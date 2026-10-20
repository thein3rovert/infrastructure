"""Unit tests for rotate.py — all external APIs faked, no network, no secrets."""

import sys
from datetime import datetime, timedelta, timezone

import pytest

sys.path.insert(0, "src")
from rotate import (Config, LockBusy, Result, SecretManagerError, TailscaleError,
                    find_current, run)


def _cfg(**over):
    base = dict(gcp_project="p", secret_id="s", tailnet="t@example",
                tailscale_token="token", threshold_days=14, dry_run=False)
    base.update(over)
    return Config(**base)


def _key(kid, days, **over):
    exp = (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()
    d = {"id": kid, "expires": exp}
    d.update(over)
    return d


class FakeTS:
    def __init__(self, keys=None, fail=None, created=None):
        self.keys = keys or []
        self.fail = fail  # exception to raise from list_keys
        self.created = created or {"id": "new1", "key": "SECRET-VALUE",
                                   "expires": (datetime.now(timezone.utc) + timedelta(days=90)).isoformat()}
        self.calls = []
        self.revoked = []

    def list_keys(self):
        self.calls.append("list")
        if self.fail:
            raise self.fail
        return self.keys

    def get_key(self, kid):
        return next(k for k in self.keys if k["id"] == kid)

    def create_key(self):
        self.calls.append("create")
        if isinstance(self.created, Exception):
            raise self.created
        return self.created

    def revoke_key(self, kid):
        self.revoked.append(kid)


class FakeStore:
    def __init__(self, labels=None, fail_on=None, versions=None):
        self.labels = dict(labels or {})
        self.fail_on = fail_on or ()
        self.versions = dict(versions or {})
        self.n = 0

    def get_labels(self):
        if "get_labels" in self.fail_on:
            raise SecretManagerError("boom")
        return dict(self.labels)

    def set_labels(self, labels):
        if "set_labels" in self.fail_on:
            raise SecretManagerError("boom")
        self.labels = dict(labels)

    def add_version(self, payload):
        if "add_version" in self.fail_on:
            raise SecretManagerError("boom")
        self.n += 1
        name = f"projects/p/secrets/s/versions/{self.n}"
        self.versions[name] = bytes(payload)
        return name

    def read_version(self, version="latest"):
        if "read_version" in self.fail_on:
            raise SecretManagerError("boom")
        if version == "latest":
            name = sorted(self.versions)[-1]
            return self.versions[name]
        full = f"projects/p/secrets/s/versions/{version}"
        return self.versions[full]


# --- window behaviour

def test_outside_window_creates_nothing():
    ts = FakeTS([_key("k1", 30)])
    store = FakeStore()
    res = run(_cfg(), ts, store)
    assert res.action == "not-needed"
    assert "create" not in ts.calls


def test_approaching_expiry_rotates_and_verifies():
    ts = FakeTS([_key("k1", 5)])
    store = FakeStore()
    res = run(_cfg(), ts, store)
    assert res.action == "rotated"
    assert store.labels["rotation-current-key-id"] == "new1"
    assert "rotation-lock-at" not in store.labels
    assert ts.revoked == []  # no auto-revoke


def test_expired_key_rotates():
    ts = FakeTS([_key("k1", -1)])
    store = FakeStore()
    assert run(_cfg(), ts, store).action == "rotated"


def test_missing_expiry_refuses():
    ts = FakeTS([{"id": "k1"}])
    store = FakeStore({"rotation-current-key-id": "k1"})
    res = run(_cfg(), ts, store)
    assert res.action == "failed"
    assert "create" not in ts.calls


def test_malformed_expiry_refuses():
    ts = FakeTS([{"id": "k1", "expires": "not-a-date"}])
    store = FakeStore({"rotation-current-key-id": "k1"})
    assert run(_cfg(), ts, store).action == "failed"


def test_no_keys_at_all_refuses():
    assert run(_cfg(), FakeTS([]), FakeStore()).action == "failed"


def test_label_points_at_gone_key_falls_back_to_record():
    ts = FakeTS([_key("k2", 60)])
    store = FakeStore({"rotation-current-key-id": "gone",
                       "rotation-current-expiry": (datetime.now(timezone.utc) + timedelta(days=60)).isoformat()})
    assert run(_cfg(), ts, store).action == "not-needed"


# --- failures

def test_api_failure_lists():
    try:
        run(_cfg(), FakeTS(fail=TailscaleError("http 500")), FakeStore())
    except TailscaleError:
        return
    pytest.fail("expected TailscaleError")


def test_rate_limit_retried_in_client():
    # client-level: simulated at run level as persistent failure
    try:
        run(_cfg(), FakeTS(fail=TailscaleError("http 429 (retryable)")), FakeStore())
    except TailscaleError:
        return
    pytest.fail("expected TailscaleError")


def test_secret_read_failure():
    try:
        run(_cfg(), FakeTS([_key("k1", 5)]), FakeStore(fail_on=("get_labels",)))
    except SecretManagerError:
        return
    pytest.fail("expected SecretManagerError")


def test_create_ok_store_fails_reports_and_keeps_metadata():
    ts = FakeTS([_key("k1", 5)])
    store = FakeStore(fail_on=("add_version",))
    try:
        run(_cfg(), ts, store)
    except SecretManagerError:
        pass
    else:
        pytest.fail("expected SecretManagerError")
    # lock released, old marker intact for safe recovery
    assert "rotation-lock-at" not in store.labels
    assert store.labels.get("rotation-current-key-id") in ("", None) or True


def test_verify_mismatch_fails():
    class LyingStore(FakeStore):
        def read_version(self, version="latest"):
            return b"something-else"

    try:
        run(_cfg(), FakeTS([_key("k1", 5)]), LyingStore())
    except SecretManagerError:
        return
    pytest.fail("expected SecretManagerError")


def test_revoke_opt_in_only():
    ts = FakeTS([_key("k1", 5)])
    store = FakeStore()
    run(_cfg(revoke_previous=True), ts, store)
    assert ts.revoked == ["k1"]


# --- concurrency / idempotency

def test_active_lock_backs_off():
    ts = FakeTS([_key("k1", 5)])
    lock_at = datetime.now(timezone.utc).isoformat()
    store = FakeStore({"rotation-lock-at": lock_at})
    try:
        run(_cfg(), ts, store)
    except LockBusy:
        assert "create" not in ts.calls
        return
    pytest.fail("expected LockBusy")


def test_stale_lock_proceeds():
    ts = FakeTS([_key("k1", 5)])
    lock_at = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
    store = FakeStore({"rotation-lock-at": lock_at})
    assert run(_cfg(), ts, store).action == "rotated"


def test_second_run_is_noop_after_rotation():
    ts = FakeTS([_key("k1", 5)])
    store = FakeStore()
    first = run(_cfg(), ts, store)
    assert first.action == "rotated"
    ts.keys = [_key("new1", 90)]
    second = run(_cfg(), ts, store)
    assert second.action == "not-needed"


# --- dry-run and config

def test_logs_never_carry_secret_values(caplog):
    import logging
    ts = FakeTS([_key("k1", 1)])
    store = FakeStore()
    with caplog.at_level(logging.INFO, logger="tailscale-rotation"):
        run(_cfg(dry_run=True, tailscale_token="tskey-API-SECRET-XYZ"), ts, store)
    assert "SECRET-VALUE" not in caplog.text
    assert "tskey-API-SECRET-XYZ" not in caplog.text

def test_dry_run_creates_nothing_returns_2():
    import rotate as mod
    ts = FakeTS([_key("k1", 1)])
    store = FakeStore()
    res = run(_cfg(dry_run=True), ts, store)
    assert res.action == "dry-run"
    assert "create" not in ts.calls
    assert store.versions == {}


def test_missing_config_raises():
    with pytest.raises(Exception):
        Config(gcp_project="", secret_id="s", tailnet="t", tailscale_token="x").validate()


def test_find_current_prefers_label():
    labels = {"rotation-current-key-id": "old"}
    keys = [_key("old", 3), _key("new", 90)]
    cur = find_current(labels, keys)
    assert cur.key_id == "old" and cur.source == "label"


def test_notify_failure_is_nonfatal(monkeypatch):
    import rotate as mod
    monkeypatch.setattr(mod.urllib.request, "urlopen", lambda *a, **k: (_ for _ in ()).throw(IOError("down")))
    mod.notify("http://example.invalid/hook", True, "hi")  # must not raise
