{
  config,
  lib,
  pkgs,
  ...
}:
let
  if-jotty-enable = lib.mkIf config.nixosSetup.services.jotty.enable;
  imageName = "ghcr.io/fccview/jotty:latest";
  host = "127.0.0.1";
  port = config.snippets.thein3rovert.networkMap.jotty.port;
  dataDir = "/var/lib/jotty";
in
{
  options.nixosSetup.services.jotty = {
    enable = lib.mkEnableOption "Jotty note-taking application";
  };

  config = if-jotty-enable {
    # Create data directories with proper permissions
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 1001 65533 -"
      "d ${dataDir}/data 0755 1001 65533 -"
      "d ${dataDir}/data/users 0755 1001 65533 -"
      "d ${dataDir}/data/checklists 0755 1001 65533 -"
      "d ${dataDir}/data/notes 0755 1001 65533 -"
      "d ${dataDir}/data/sharing 0755 1001 65533 -"
      "d ${dataDir}/cache 0755 1001 65533 -"
      "d ${dataDir}/config 0755 1001 65533 -"
    ];

    myContainers.traefik = {
      enable = true;
      defaultEntryPoints = [ "websecure" ];
      defaultCertResolver = "cloudflare";
    };

    myContainers = {
      enable = true;
      containers = {
        jotty = {
          image = imageName;
          ports = [ "${host}:${toString port}:3000" ];
          volumes = [
            "${dataDir}/data:/app/data:rw"
            "${dataDir}/config:/app/config:ro"
            "${dataDir}/cache:/app/.next/cache:rw"
          ];
          environment = {
            NODE_ENV = "production";
          };
          traefik = {
            enable = true;
            url = "http://localhost:${toString port}/";
            rule = "Host(`jotty.thein3rovert.dev`)";
          };
        };
      };
    };
  };
}
