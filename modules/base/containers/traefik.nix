{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    types
    mkIf
    mkMerge
    mapAttrsToList
    optionalAttrs
    ;
  cfg = config.myContainers; # Refrence myContainer config in base

  # Functions
  If = mkIf;
  merge = mkMerge;
  convertAttributeSetToList = mapAttrsToList;

  # Types
  createOption = mkOption;
  boolean = types.bool;
  list = types.listOf;
  string = types.str;

in
{
  options.myContainers = {
    traefik = {
      enable = createOption {
        type = boolean;
        default = false;
        description = "Enable Traefil integration for contaoiners";
      };

      defaultEntryPoints = createOption {
        type = list string;
        default = [ "websecure" ];
        description = "Default entry points for Traefik routers";
      };

      defaultCertResolver = createOption {
        type = string;
        default = "cloudflare";
        description = "Default certificate resolver";
      };
    };
  };

  config = If cfg.traefik.enable {
    services.traefik.dynamicConfigOptions.http = merge (
      convertAttributeSetToList (
        containerName: containerCfg:

        let
          traefikCfg = containerCfg.traefik or null;
          # If traefik config is not enabled return false
          hasTraefikEnabled = traefikCfg != null && traefikCfg.enable or false;
          baseEntryPoint = cfg.traefik.defaultEntryPoints;
          baseCertResolver = cfg.traefik.defaultCertResolver;
        in
        If hasTraefikEnabled {
          # Services configuration
          services.${containerName}.loadBalancer.servers = [
            {
              url = traefikCfg.url or (throw "Missing 'url' for Traefik service integration ${containerName}");
            }
          ];

          # Load balancer router config
          routers.${containerName} = mkMerge [
            {
              rule = traefikCfg.rule or (throw "Missing 'rule' for Traefik router ${containerName}");
              service = containerName;
              entryPoints = traefikCfg.defaultEntryPoints or baseEntryPoint;
            }

            (optionalAttrs (traefikCfg.tls.enable or true) {
              tls = mkMerge [
                {
                  certResolver = traefikCfg.tls.defaultCertResolver or baseCertResolver;
                }

              ];
            })

          ];
        }
      ) cfg.containers
    );
  };
}
