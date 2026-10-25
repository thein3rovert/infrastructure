{
  config,
  lib,
  ...
}:
let

  if-glance-enable = lib.mkIf config.nixosSetup.services.glance.enable;
  imageName = "glanceapp/glance";
  host = "100.105.187.63";
  port = 8280;

  # Use lib.path.append to safely handle relative paths
  glanceSrc = lib.path.append ./. "config";
  glanceSrc2 = builtins.toPath ./glance/.;
  glanceSecret = config.age.secrets.glance.path;
  # glanceConfig = "/home/thein3rovert/.config/glance/config";
  glanceConfig = "/etc/glance/config";
  glanceTimeZone = "/etc/timezone";
  glanceLocalTime = "/etc/localtime";
  # glanceAssets = "/home/thein3rovert/.config/glance/config/assets";
  glanceAssets = "/etc/glance/config/assets";
in
{
  options.nixosSetup.services.glance = {
    enable = lib.mkEnableOption "Glance Dashboard";
  };

  config = if-glance-enable {
    # system-wide glance config files
    environment.etc = {
      "glance/config/glance.yml" = {
        source = "${glanceSrc}/glance.yml";
        mode = "0644";
      };
      "glance/config/.env" = {
        source = glanceSecret;
        mode = "0644";
      };
      "glance/config/assets/penguin.png" = {
        source = "${glanceSrc}/assets/penguin.png";
        mode = "0644";
      };
    };

    # Another way
    # environment.etc."glance-env".target = "glance/.env2";
    # environment.etc."glance-env".source = glanceSecret;

    myContainers.traefik = {
      enable = true;
      defaultEntryPoints = [ "websecure" ];
      defaultCertResolver = "cloudflare";
    };
    myContainers = {
      enable = true;
      containers = {
        glance = {
          image = "${imageName}";
          ports = [ "${host}:${toString port}:8080" ];
          volumes = [
            "${glanceConfig}:/app/config"
            "${glanceLocalTime}:/etc/localtime:ro"
            "${glanceTimeZone}:/etc/timezone:ro"
            "${glanceAssets}:/app/assets"
          ];
          environment = {
            LD_DISABLE_BACKGROUND_TASKS = "true";
            BASE_DOMAIN = "thein3rovert.dev";
          };
          traefik = {
            enable = true;
            # Point glance to tailscale network for local services
            # Change back to localhost if no tailscale
            url = "http://100.105.187.63:8280/";
            rule = "Host(`glance.thein3rovert.dev`)";
          };

        };
      };
    };
  };
}
