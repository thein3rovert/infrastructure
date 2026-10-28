{
  config,
  lib,
  ...
}:
let

  if-uptime-kuma-enable = lib.mkIf config.nixosSetup.services.uptime-kuma.enable;
  imageName = "docker.io/louislam/uptime-kuma";
  imageTag = "2.5.5";
  host = "127.0.0.1";
  port = 8380;
  dataVolume = "uptime-kuma_data";
in
{
  options.nixosSetup.services.uptime-kuma = {
    enable = lib.mkEnableOption "Monitoring";
  };

  config = if-uptime-kuma-enable {

    myContainers.traefik = {
      enable = true;
      defaultEntryPoints = [ "websecure" ];
      defaultCertResolver = "cloudflare";
    };
    myContainers = {
      enable = true;
      containers = {
        uptime-kuma = {
          image = "${imageName}:${imageTag}";
          ports = [ "${host}:${toString port}:3001" ];
          volumes = [
            "${dataVolume}:/app/data"
          ];
          extraOptions = [ "--cap-add=NET_RAW" ];
          labels = {
            "io.containers.autoupdate" = "registry";
          };
          traefik = {
            enable = true;
            url = "http://localhost:8380/";
            rule = "Host(`uptime-kuma.thein3rovert.dev`)";
          };

        };
      };
    };

    # Use if nixos servcics is handling uptime-kuma
    # systemd.services.uptime-kuma = {
    #   serviceConfig = {
    #     AmbientCapabilities = [ "CAP_NET_RAW" ];
    #     CapabilityBoundingSet = [ "CAP_NET_RAW" ];
    #   };
    # };
  };
}
