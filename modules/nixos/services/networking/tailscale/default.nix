{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  options.nixosSetup.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN services";

    authKeyFile = lib.mkOption {
      description = "Key file used for authentication";
      default = config.age.secrets.tailscale.path or null; # Dont have the auth key file yet
      type = lib.types.nullOr lib.types.path;
    };

  };

  config = lib.mkIf config.nixosSetup.services.tailscale.enable {
    /*
      An assertion is a condition that must be true for the configuration to be valid.
      If the condition is false, Nix will raise an error and stop the build or evaluation.assertions

      The assertions attribute is expected to be a list of assertion objects.
      Each object inside the list is a set with two fields: aassertion and message
    */
    assertions = [
      {
        assertion = config.nixosSetup.services.tailscale.authKeyFile != null;
        message = "config.tailscale.authenticationKeyFile cannot be null.";
      }
    ];

    networking.firewall = {
      allowedUDPPorts = [ config.services.tailscale.port ];
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };

    services = {
      tailscale = {
        permitCertUid = "traefik";
        # We can also try it this way
        # inherit (config.nixosSetup.services.taiLscale) aauthKeyFile;
        authKeyFile = config.nixosSetup.services.tailscale.authKeyFile;
        enable = true;
        extraUpFlags = [
          "--ssh"
          "--reset"
        ];
        openFirewall = true;
        useRoutingFeatures = "both";
      };
    };

  };
}
