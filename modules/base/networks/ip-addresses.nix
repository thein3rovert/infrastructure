{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  string = types.str;
  attributeSetOf = types.attrsOf;
  ip-base = "192.168.0";
in
{
  # ============================================
  # IP Addresses Options
  # ============================================
  options.homelab = {
    ipAddresses = mkOption {
      type = attributeSetOf (
        types.submodule {
          options = {
            ip = mkOption {
              type = string;
              description = "Local network IP address";
              default = "127.0.0.1";
            };
            tailscaleIp = mkOption {
              type = string;
              default = "";
              description = "Tailscale IP address";
            };
          };
        }
      );
      default = { };
      description = "IP addresses for each homelab host/server";
    };
  };

  # ============================================
  # IP Addresses Configuration
  #
  # /*
  #  Local Services: Services running on the main host (127.0.0.1)
  #  LXC Containers: Services running in LXC containers (10.10.10.x)
  #  VM Services: Services running in virtual machines (10.20.0.x)
  #  Tailscale Services: Services accessible via Tailscale VPN (100.x.x.x)
  #  Production VPS: Services running on the production VPS (bellamy)
  # */
  #
  # ============================================
  config.homelab = {
    ipAddresses = {
      # ============================================
      # Local Services
      # ============================================
      localhost = {
        ip = "127.0.0.1";
        tailscaleIp = "";
      };

      # ============================================
      # LXC Container Hosts
      # ============================================
      emily = {
        ip = "";
        tailscaleIp = "100.105.217.77";
      };
      roan = {
        ip = "${ip-base}.103";
        tailscaleIp = "100.99.235.113";
      };
      zeke = {
        ip = "${ip-base}.106";
        tailscaleIp = "100.74.26.17";
      };
      finn = {
        ip = "${ip-base}.51";
        tailscaleIp = "100.91.36.84";
      };
      lexa = {
        ip = "10.10.10.7";
        tailscaleIp = "100.88.29.64";
      };
      marcus = {
        ip = "${ip-base}.19";
        tailscaleIp = "100.94.20.21";
      };

      # ============================================
      # Production VPS
      # ============================================
      bellamy = {
        ip = "95.216.216.22";
        tailscaleIp = "100.105.187.63";
      };

      # ============================================
      # VM Services
      # ============================================
      wellsjaha = {
        ip = "10.20.0.1";
        tailscaleIp = "100.103.139.31";
      };
      k3s-server = {
        ip = "10.10.20.100";
        tailscaleIp = "100.85.190.19";
      };
      octavia = {
        ip = "192.168.0.113";
        tailscaleIp = "100.106.96.97";
      };
      raven = {
        ip = "192.168.0.111";
        tailscaleIp = "100.123.5.107";
      };
      becca = {
        ip = "${ip-base}.101";
        tailscaleIp = "100.123.31.22";
      };
      # ============================================
      # Tailscale Only (no local IP)
      # ============================================
      nixos = {
        ip = "127.0.0.1";
        tailscaleIp = "100.105.217.77";
      };
      nixos-runner = {
        tailscaleIp = "100.111.90.52";
      };
      srv-prod-01 = {
        tailscaleIp = "100.92.136.66";
      };
      node-0 = {
        tailscaleIp = "100.72.97.99";
      };
      node-1 = {
        tailscaleIp = "100.90.77.80";
      };
      server = {
        tailscaleIp = "100.68.106.100";
      };
      ipad = {
        tailscaleIp = "100.77.165.98";
      };
      iphone = {
        tailscaleIp = "100.111.254.114";
      };
      ubuntu-ct-01 = {
        tailscaleIp = "100.110.115.126";
      };

      # ============================================
      # Podman Bridge
      # ============================================
      podman0 = {
        ip = "10.88.0.0";
        tailscaleIp = "";
      };
      podman-web = {
        ip = "10.89.0.0";
        tailscaleIp = "";
      };
    };
  };
}
