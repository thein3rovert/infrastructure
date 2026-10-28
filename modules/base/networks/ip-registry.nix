{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  networkMap = config.myDns.networkMap.localNetworkMap;
  prodMap = config.snippets.thein3rovert.networkMap;
  hosts = config.homelab.ipAddresses;
in
{
  # ============================================
  # IP Registry Options
  # ============================================
  options.homelab.ipRegistry = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          ip = mkOption {
            type = types.str;
            description = "IP address";
            default = "127.0.0.1";
          };
          port = mkOption {
            type = types.either types.int types.str;
            description = "Port number";
          };
          url = mkOption {
            type = types.str;
            description = "Full URL (auto-generated)";
            readOnly = true;
          };
        };
      }
    );
    default = { };
    description = "Centralized IP registry for services";
  };

  # ============================================
  # IP Registry Configuration
  #
  # /*
  #  Local Services: Services running on localhost (127.0.0.1)
  #  Container Services: Services running in LXC containers
  #  VM Services: Services running in virtual machines
  #  Tailscale Services: Services accessible via Tailscale VPN
  #  Production VPS: Services running on the production VPS
  # */
  #
  # ============================================
  config.homelab.ipRegistry = {
    # ============================================
    # Local Services
    # ============================================
    zerobyte = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.zerobyte.port;
      url = "${config.homelab.ipRegistry.zerobyte.ip}:${toString config.homelab.ipRegistry.zerobyte.port}";
    };
    grafana = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.grafana.port;
      url = "${config.homelab.ipRegistry.grafana.ip}:${toString config.homelab.ipRegistry.grafana.port}";
    };
    loki = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.loki.port;
      url = "${config.homelab.ipRegistry.loki.ip}:${toString config.homelab.ipRegistry.loki.port}";
    };

    # ============================================
    # Container LXC Services
    # ============================================
    dbpro-studio = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.dbpro-studio.port;
      url = "${config.homelab.ipRegistry.dbpro-studio.ip}:${toString config.homelab.ipRegistry.dbpro-studio.port}";
    };
    ad-guard = {
      ip = hosts.finn.ip;
      port = networkMap.ad-guard.port;
      url = "${config.homelab.ipRegistry.ad-guard.ip}:${toString config.homelab.ipRegistry.ad-guard.port}";
    };
    technitium = {
      ip = hosts.zeke.tailscaleIp;
      port = networkMap.technitium.port;
      url = "${config.homelab.ipRegistry.technitium.ip}:${toString config.homelab.ipRegistry.technitium.port}";
    };
    n8n = {
      ip = hosts.emily.ip;
      port = networkMap.n8n.port;
      url = "${config.homelab.ipRegistry.n8n.ip}:${toString config.homelab.ipRegistry.n8n.port}";
    };
    kestra = {
      ip = hosts.marcus.tailscaleIp;
      port = networkMap.kestra.port;
      url = "${config.homelab.ipRegistry.kestra.ip}:${toString config.homelab.ipRegistry.kestra.port}";
    };
    termix = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.termix.port;
      url = "${config.homelab.ipRegistry.termix.ip}:${toString config.homelab.ipRegistry.termix.port}";
    };
    fossflow = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.fossflow.port;
      url = "${config.homelab.ipRegistry.fossflow.ip}:${toString config.homelab.ipRegistry.fossflow.port}";
    };
    dockhand = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.dockhand.port;
      url = "${config.homelab.ipRegistry.dockhand.ip}:${toString config.homelab.ipRegistry.dockhand.port}";
    };
    incus = {
      ip = hosts.emily.ip;
      port = networkMap.incus.port;
      url = "${config.homelab.ipRegistry.incus.ip}:${toString config.homelab.ipRegistry.incus.port}";
    };
    incus-v2 = {
      ip = hosts.marcus.tailscaleIp;
      port = networkMap.incus-v2.port;
      url = "${config.homelab.ipRegistry.incus-v2.ip}:${toString config.homelab.ipRegistry.incus-v2.port}";
    };
    copyparty = {
      ip = hosts.emily.ip;
      port = networkMap.copyparty.port;
      url = "${config.homelab.ipRegistry.copyparty.ip}:${toString config.homelab.ipRegistry.copyparty.port}";
    };
    filebrowser = {
      ip = hosts.emily.ip;
      port = networkMap.filebrowser.port;
      url = "${config.homelab.ipRegistry.filebrowser.ip}:${toString config.homelab.ipRegistry.filebrowser.port}";
    };

    # ============================================
    # VM Services
    # ============================================
    linkding = {
      ip = hosts.raven.tailscaleIp;
      port = networkMap.linkding.port;
      # url = "${config.homelab.ipRegistry.linkding.ip}:${toString config.homelab.ipRegistry.linkding.port}";
      url = "${config.homelab.ipRegistry.linkding.ip}:80";
    };
    longhorn = {
      ip = hosts.raven.tailscaleIp;
      port = networkMap.longhorn.port;
      url = "${config.homelab.ipRegistry.longhorn.ip}:${toString config.homelab.ipRegistry.longhorn.port}";
    };
    argocd = {
      ip = hosts.raven.tailscaleIp;
      port = networkMap.argocd.port;
      url = "${config.homelab.ipRegistry.argocd.ip}:${toString config.homelab.ipRegistry.argocd.port}";
    };
    kaneo = {
      ip = hosts.roan.tailscaleIp;
      port = networkMap.kaneo.port;
      url = "${config.homelab.ipRegistry.kaneo.ip}:${toString config.homelab.ipRegistry.kaneo.port}";
    };

    # ============================================
    # Tailscale Services
    # ============================================
    syncthing = {
      ip = hosts.nixos.tailscaleIp;
      port = networkMap.syncthing.port;
      url = "${config.homelab.ipRegistry.syncthing.ip}:${toString config.homelab.ipRegistry.syncthing.port}";
    };
    vault = {
      # Migrated from becca to srv-prod-01 (PLB-012); becca entry kept above for reference.
      ip = hosts.srv-prod-01.tailscaleIp;
      port = networkMap.vault.port;
      url = "${config.homelab.ipRegistry.vault.ip}:${toString config.homelab.ipRegistry.vault.port}";
    };
    # NOTE: Garage migrated to the nixos host (HML-036).
    # Bellamy's public Traefik proxies s3.thein3rovert.dev to this address over Tailscale.
    garage-webui = {
      ip = hosts.localhost.ip;
      port = networkMap.garage-webui.port;
      url = "${config.homelab.ipRegistry.garage-webui.ip}:${toString config.homelab.ipRegistry.garage-webui.port}";
    };

    # ============================================
    # Production VPS Services
    #
    # /* Services running on bellamy VPS (localhost)
    # */
    #
    # ============================================
    say-cheese = {
      ip = "localhost";
      port = prodMap.say-cheese.port;
      url = "${config.homelab.ipRegistry.say-cheese.ip}:${toString config.homelab.ipRegistry.say-cheese.port}";
    };
    # NOTE: Garage storage now runs on the nixos host (HML-036).
    # Bellamy Traefik terminates s3.thein3rovert.dev and proxies to this Tailscale address.
    garage = {
      # Since we're move garage from bellamy,for bellamy to
      # access it and proxies to it..we can only do this through
      # tailscale
      ip = hosts.nixos.tailscaleIp;
      port = prodMap.garage-api.port;
      url = "${config.homelab.ipRegistry.garage.ip}:${toString config.homelab.ipRegistry.garage.port}";
    };
    memos = {
      ip = "localhost";
      port = prodMap.memos.port;
      url = "${config.homelab.ipRegistry.memos.ip}:${toString config.homelab.ipRegistry.memos.port}";
    };
    forgejo = {
      ip = "localhost";
      port = prodMap.forgejo.port;
      url = "${config.homelab.ipRegistry.forgejo.ip}:${toString config.homelab.ipRegistry.forgejo.port}";
    };
    blog = {
      ip = "localhost";
      port = prodMap.blog.port;
      url = "${config.homelab.ipRegistry.blog.ip}:${toString config.homelab.ipRegistry.blog.port}";
    };
  };
}
