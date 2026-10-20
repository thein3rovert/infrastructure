"""Tailscale auth-key expiry monitoring and rotation.

Scheduled Cloud Run Job (or local run). Reads the shared reusable auth key
metadata from the Tailscale API, and when expiry is within the rotation
threshold, mints a replacement and stores it as a new GCP Secret Manager
version. Safe defaults: dry-run off by env, no auto-revoke, no secrets logs.

Exit codes: 0 ok / not-needed, 2 rotation needed but dry-run, 1 failure.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone


# ---------------------------------------------------------------- config

def _env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name, "")
    if not raw.strip():
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise ConfigError(f"{name} must be an integer, got {raw!r}") from exc


def _env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name, "")
    if not raw.strip():
        return default
    return raw.strip().lower() in ("1", "true", "yes", "on")


@dataclass
class Config:
    gcp_project: str = ""
    secret_id: str = ""
    tailnet: str = ""
    tailscale_token: str = ""  # NEVER logged
    threshold_days: int = 14
    key_ttl_seconds: int = 7776000  # 90 days
    key_reusable: bool = True
    key_ephemeral: bool = False
    key_preauthorized: bool = True
    key_tags: tuple = ()
    key_description: str = "managed-rotation"
    dry_run: bool = False
    revoke_previous: bool = False
    notify_webhook_url: str = ""
    lock_ttl_seconds: int = 900
    api_base: str = "https://api.tailscale.com"

    @classmethod
    def from_env(cls) -> "Config":
        tags = tuple(t for t in _env("KEY_TAGS", "").split(",") if t.strip())
        cfg = cls(
            gcp_project=_env("GCP_PROJECT").strip(),
            secret_id=_env("SECRET_ID").strip(),
            tailnet=_env("TAILNET").strip(),
            tailscale_token=_env("TAILSCALE_API_TOKEN"),
            threshold_days=_env_int("ROTATION_THRESHOLD_DAYS", 14),
            key_ttl_seconds=_env_int("KEY_TTL_SECONDS", 7776000),
            key_reusable=_env_bool("KEY_REUSABLE", True),
            key_ephemeral=_env_bool("KEY_EPHEMERAL", False),
            key_preauthorized=_env_bool("KEY_PREAUTHORIZED", True),
            key_tags=tags,
            key_description=_env("KEY_DESCRIPTION", "managed-rotation").strip() or "managed-rotation",
            dry_run=_env_bool("DRY_RUN", False),
            revoke_previous=_env_bool("REVOKE_PREVIOUS", False),
            notify_webhook_url=_env("NOTIFY_WEBHOOK_URL").strip(),
            lock_ttl_seconds=_env_int("LOCK_TTL_SECONDS", 900),
        )
        cfg.validate()
        return cfg

    def validate(self) -> None:
        missing = [n for n in ("GCP_PROJECT", "SECRET_ID", "TAILNET", "TAILSCALE_API_TOKEN")
                   if not getattr(self, {"GCP_PROJECT": "gcp_project", "SECRET_ID": "secret_id",
                                          "TAILNET": "tailnet", "TAILSCALE_API_TOKEN": "tailscale_token"}[n])]
        if missing:
            raise ConfigError(f"missing required config: {', '.join(missing)}")
        if self.threshold_days < 0:
            raise ConfigError("ROTATION_THRESHOLD_DAYS must be >= 0")
        if self.key_ttl_seconds <= 0:
            raise ConfigError("KEY_TTL_SECONDS must be > 0")


class ConfigError(Exception):
    pass


class TailscaleError(Exception):
    pass


class SecretManagerError(Exception):
    pass


class LockBusy(Exception):
    pass


# ---------------------------------------------------------------- logging (never secrets)

LOG = logging.getLogger("tailscale-rotation")


def setup_logging() -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(logging.Formatter(
        '{"ts":"%(asctime)s","level":"%(levelname)s","msg":"%(message)s"}'))
    LOG.addHandler(handler)
    LOG.setLevel(logging.INFO)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


# ---------------------------------------------------------------- tailscale API (lazy import-free, stdlib http)

class TailscaleClient:
    def __init__(self, cfg: Config, opener=None):
        self.cfg = cfg
        self._opener = opener  # test seam

    def _request(self, method: str, path: str, body: dict | None = None,
                 retries: int = 3) -> dict:
        url = self.cfg.api_base + path
        data = json.dumps(body).encode() if body is not None else None
        last: Exception | None = None
        for attempt in range(retries):
            req = urllib.request.Request(url, data=data, method=method,
                                         headers={"Authorization": f"Bearer {self.cfg.tailscale_token}",
                                                  "Content-Type": "application/json"})
            try:
                if self._opener is not None:
                    return self._opener(req)
                with urllib.request.urlopen(req, timeout=30) as resp:
                    return json.loads(resp.read().decode() or "{}")
            except urllib.error.HTTPError as exc:
                if exc.code == 429 or 500 <= exc.code < 600:
                    last = TailscaleError(f"Tailscale {method} {path}: http {exc.code} (retryable)")
                    time.sleep(min(2 ** attempt, 8))
                    continue
                if exc.code in (401, 403):
                    raise TailscaleError(f"Tailscale {method} {path}: http {exc.code} (auth failed, check credential)") from exc
                raise TailscaleError(f"Tailscale {method} {path}: http {exc.code}") from exc
            except (urllib.error.URLError, TimeoutError, OSError) as exc:
                last = TailscaleError(f"Tailscale {method} {path}: transport error: {exc}")
                time.sleep(min(2 ** attempt, 8))
        raise last or TailscaleError("unreachable")

    def list_keys(self) -> list[dict]:
        out = self._request("GET", f"/api/v2/tailnet/{self.cfg.tailnet}/keys")
        keys = out.get("keys", [])
        if not isinstance(keys, list):
            raise TailscaleError("malformed keys response: 'keys' is not a list")
        return keys

    def get_key(self, key_id: str) -> dict:
        return self._request("GET", f"/api/v2/tailnet/{self.cfg.tailnet}/keys/{key_id}")

    def create_key(self) -> dict:
        body = {
            "capabilities": {"devices": {"create": {
                "reusable": self.cfg.key_reusable,
                "ephemeral": self.cfg.key_ephemeral,
                "preauthorized": self.cfg.key_preauthorized,
            }}},
            "expirySeconds": self.cfg.key_ttl_seconds,
            "description": f"{self.cfg.key_description}-{_now():%Y%m%d}",
        }
        if self.cfg.key_tags:
            body["tags"] = list(self.cfg.key_tags)
        out = self._request("POST", f"/api/v2/tailnet/{self.cfg.tailnet}/keys", body)
        if not out.get("id") or not out.get("key"):
            raise TailscaleError("create-key response missing id/key")
        return out

    def revoke_key(self, key_id: str) -> None:
        self._request("DELETE", f"/api/v2/tailnet/{self.cfg.tailnet}/keys/{key_id}")


# ---------------------------------------------------------------- secret manager (lazy google import so tests stay light)

class SecretStore:
    """Thin wrapper; google-cloud-secret-manager imported lazily."""

    def __init__(self, cfg: Config, client=None):
        self.cfg = cfg
        self._client = client
        self._sm = None

    def _api(self):
        if self._client is not None:
            return self._client
        if self._sm is None:
            from google.cloud import secretmanager  # type: ignore
            self._sm = secretmanager
        return self._sm

    def _parent(self) -> str:
        return f"projects/{self.cfg.gcp_project}/secrets/{self.cfg.secret_id}"

    def get_labels(self) -> dict:
        sm = self._api()
        try:
            if self._client is not None:
                return dict(self._client.get_labels())
            secret = sm.SecretManagerServiceClient().get_secret(request={"name": self._parent()})
            return dict(secret.labels)
        except Exception as exc:
            raise SecretManagerError(f"read secret metadata failed: {exc}") from exc

    def set_labels(self, labels: dict) -> None:
        sm = self._api()
        try:
            if self._client is not None:
                self._client.set_labels(labels)
                return
            client = sm.SecretManagerServiceClient()
            client.update_secret(request={
                "secret": {"name": self._parent(), "labels": labels},
                "update_mask": {"paths": ["labels"]},
            })
        except Exception as exc:
            raise SecretManagerError(f"update secret labels failed: {exc}") from exc

    def add_version(self, payload: bytes) -> str:
        sm = self._api()
        try:
            if self._client is not None:
                return self._client.add_version(payload)
            client = sm.SecretManagerServiceClient()
            version = client.add_secret_version(
                request={"parent": self._parent(), "payload": {"data": payload}})
            return version.name
        except Exception as exc:
            raise SecretManagerError(f"add secret version failed: {exc}") from exc

    def read_version(self, version: str = "latest") -> bytes:
        sm = self._api()
        try:
            if self._client is not None:
                return self._client.read_version(version)
            client = sm.SecretManagerServiceClient()
            resp = client.access_secret_version(request={"name": f"{self._parent()}/versions/{version}"})
            return bytes(resp.payload.data)
        except Exception as exc:
            raise SecretManagerError(f"read secret version failed: {exc}") from exc


# ---------------------------------------------------------------- rotation state in secret labels (no new infra)

LABEL_CURRENT_ID = "rotation-current-key-id"
LABEL_CURRENT_EXPIRY = "rotation-current-expiry"
LABEL_LOCK_AT = "rotation-lock-at"

LOCKED_BY_ME = "rotation-lock-owner"


@dataclass
class KeyState:
    key_id: str
    expires: datetime | None
    source: str  # label | api-match | unknown


def find_current(labels: dict, keys: list[dict]) -> KeyState:
    """Resolve the tracked key: label id first, else newest reusable match."""
    by_id = {k.get("id"): k for k in keys if isinstance(k, dict) and k.get("id")}
    labelled = (labels.get(LABEL_CURRENT_ID) or "").strip()
    if labelled:
        meta = by_id.get(labelled)
        exp = _safe_expiry(meta) if meta else None
        if exp is None:
            exp_raw = (labels.get(LABEL_CURRENT_EXPIRY) or "").strip()
            exp = _try_parse(exp_raw)
        return KeyState(labelled, exp, "label")
    # Fallback: newest key with an expiry (tracking record may predate labels).
    newest: dict | None = None
    for k in keys:
        exp = _safe_expiry(k)
        if exp is None:
            continue
        if newest is None or exp > (_safe_expiry(newest) or exp):
            newest = k
    if newest is None:
        return KeyState("", None, "unknown")
    return KeyState(newest["id"], _safe_expiry(newest), "api-match")


def _safe_expiry(meta: dict | None) -> datetime | None:
    if not meta:
        return None
    return _try_parse(str(meta.get("expires") or ""))


def _try_parse(raw: str) -> datetime | None:
    try:
        return _parse_time(raw) if raw.strip() else None
    except (ValueError, AttributeError):
        return None


def days_left(expires: datetime | None) -> float | None:
    if expires is None:
        return None
    return (expires - _now()).total_seconds() / 86400.0


# ---------------------------------------------------------------- notify (best effort, never secrets)

def notify(url: str, ok: bool, text: str) -> None:
    if not url:
        return
    try:
        req = urllib.request.Request(
            url, data=json.dumps({"ok": ok, "service": "tailscale-key-rotation",
                                  "msg": text}).encode(),
            headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=10):
            pass
        LOG.info("notify sent ok=%s", ok)
    except Exception as exc:
        LOG.warning("notify failed (non-fatal): %s", exc)


# ---------------------------------------------------------------- main flow

@dataclass
class Result:
    action: str  # ok | rotated | dry-run | not-needed | failed
    key_id: str = ""
    detail: str = ""


def run(cfg: Config, ts: TailscaleClient | None = None,
        store: SecretStore | None = None) -> Result:
    ts = ts or TailscaleClient(cfg)
    store = store or SecretStore(cfg)

    labels = store.get_labels()
    keys = ts.list_keys()
    current = find_current(labels, keys)
    remaining = days_left(current.expires)

    LOG.info("current key_id=%s source=%s expires=%s days_left=%s threshold=%s",
             current.key_id or "none", current.source,
             current.expires.isoformat() if current.expires else "unknown",
             f"{remaining:.1f}" if remaining is not None else "unknown",
             cfg.threshold_days)

    if remaining is None:
        msg = f"missing expiry metadata for key {current.key_id or 'unknown'}; refusing blind rotation"
        LOG.error(msg)
        notify(cfg.notify_webhook_url, False, msg)
        return Result("failed", current.key_id, msg)

    if remaining > cfg.threshold_days:
        LOG.info("rotation not required")
        return Result("not-needed", current.key_id, f"{remaining:.1f}d left")

    if cfg.dry_run:
        msg = f"rotation WOULD run: key {current.key_id} expires in {remaining:.1f}d"
        LOG.info(msg)
        return Result("dry-run", current.key_id, msg)

    # --- lock (label lease; concurrent runners back off)
    lock_at = _try_parse(labels.get(LABEL_LOCK_AT, ""))
    if lock_at and (_now() - lock_at).total_seconds() < cfg.lock_ttl_seconds:
        raise LockBusy(f"rotation locked at {lock_at.isoformat()}")

    new_labels = dict(labels)
    new_labels[LABEL_LOCK_AT] = _now().isoformat()
    new_labels[LOCKED_BY_ME] = "true"
    store.set_labels(new_labels)
    LOG.info("lock acquired")

    try:
        created = ts.create_key()
        new_id = created["id"]
        new_exp = _safe_expiry(created) or (_now() + timedelta(seconds=cfg.key_ttl_seconds))
        LOG.info("created replacement key_id=%s expires=%s", new_id, new_exp.isoformat())

        payload = created["key"].encode()
        digest = hashlib.sha256(payload).hexdigest()
        version_name = store.add_version(payload)
        LOG.info("stored version=%s", version_name)

        roundtrip = store.read_version(version_name.split("/")[-1])
        if hashlib.sha256(roundtrip).hexdigest() != digest:
            raise SecretManagerError("verification read-back mismatch")
        LOG.info("verified round-trip for version=%s", version_name)

        final_labels = dict(new_labels)
        final_labels[LABEL_CURRENT_ID] = new_id
        final_labels[LABEL_CURRENT_EXPIRY] = new_exp.isoformat()
        final_labels.pop(LABEL_LOCK_AT, None)
        final_labels.pop(LOCKED_BY_ME, None)
        store.set_labels(final_labels)
        LOG.info("marked key_id=%s current", new_id)

        if cfg.revoke_previous and current.key_id and current.key_id != new_id:
            ts.revoke_key(current.key_id)
            LOG.info("revoked previous key_id=%s (explicitly configured)", current.key_id)
        else:
            LOG.info("previous key retained (revocation disabled by default)")

        notify(cfg.notify_webhook_url, True, f"rotated to key {new_id}")
        return Result("rotated", new_id, version_name)
    except Exception:
        try:
            keep = dict(store.get_labels())
            keep.pop(LABEL_LOCK_AT, None)
            keep.pop(LOCKED_BY_ME, None)
            store.set_labels(keep)
        except Exception as exc:
            LOG.warning("lock release failed: %s", exc)
        raise


def main() -> int:
    setup_logging()
    try:
        cfg = Config.from_env()
    except ConfigError as exc:
        LOG.error("bad config: %s", exc)
        return 1
    if cfg.dry_run:
        LOG.info("dry-run mode: no keys created, no versions stored")
    try:
        result = run(cfg)
    except LockBusy as exc:
        LOG.warning("skipped: %s", exc)
        return 0
    except (TailscaleError, SecretManagerError) as exc:
        LOG.error("rotation failed: %s", exc)
        notify(cfg.notify_webhook_url, False, f"rotation failed: {exc}")
        return 1
    if result.action == "dry-run":
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
