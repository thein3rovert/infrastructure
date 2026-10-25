{
  config,
  lib,
  pkgs,
  ...
}:
let

  if-blog-enable = lib.mkIf config.nixosSetup.services.blog.enable;
  imageName = "theintrovert/blog.thein3rovert.dev";
  imageTag = "latest";
  port = 8084;
in
{
  options.nixosSetup.services.blog = {
    enable = lib.mkEnableOption "My personal Blog";
  };

  config = if-blog-enable {
    virtualisation.oci-containers.containers.blog = {
      image = "${imageName}:${imageTag}";
      ports = [ "${toString port}:80" ];
    };

    # Auto-update: poll Docker Hub on a timer and restart the blog only when
    # the image actually changed (digest compare), so no needless restarts.
    systemd.services.blog-image-update = {
      description = "Pull the latest blog image and restart the blog if it changed";
      serviceConfig.Type = "oneshot";
      script = ''
        old="$(${lib.getExe pkgs.podman} image inspect ${imageName}:${imageTag} --format '{{.Id}}' 2>/dev/null || echo missing)"
        ${lib.getExe pkgs.podman} pull ${imageName}:${imageTag}
        new="$(${lib.getExe pkgs.podman} image inspect ${imageName}:${imageTag} --format '{{.Id}}')"
        if [ "$old" != "$new" ]; then
          ${lib.getExe' pkgs.systemd "systemctl"} restart podman-blog.service
        fi
      '';
    };

    systemd.timers.blog-image-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "10min";
        RandomizedDelaySec = "2min";
      };
    };
  };
}
