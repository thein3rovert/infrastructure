{
  config,
  lib,
  ...
}:
{
  # Define options schema - mkEnableOption creates a boolean option with default false
  # wrapping in inside enable it better
  options.nixosSetup.services.minio = {
    enable = lib.mkEnableOption "S3 services";
  };
  config = lib.mkIf config.nixosSetup.services.minio.enable {

    services.minio = {
      enable = true;
      region = "eu-central-1";
      consoleAddress = ":${toString (builtins.elemAt config.snippets.thein3rovert.networkMap.s3.port 0)}";
      listenAddress = ":${toString (builtins.elemAt config.snippets.thein3rovert.networkMap.s3.port 1)}";
      browser = true;
      rootCredentialsFile = config.age.secrets.minio.path;
      dataDir = [ "/var/storage/s3" ];
    };

    services.traefik.dynamicConfigOptions.http = {

      services.minio-console.loadBalancer.servers = [
        {
          url = "http://localhost:${toString (builtins.elemAt config.snippets.thein3rovert.networkMap.s3.port 0)}/";
        }
      ];
      services.minio.loadBalancer.servers = [
        {
          url = "http://localhost:${toString (builtins.elemAt config.snippets.thein3rovert.networkMap.s3.port 1)}/";
        }
      ];
      # === Routes ===
      routers.minio-console = {
        rule = "Host(`${builtins.elemAt config.snippets.thein3rovert.networkMap.s3.vHost 0}`)";
        service = "minio-console";
        entryPoints = [ "websecure" ];
        tls = {
          certResolver = "cloudflare";
        };
      };
      # === Routes ===
      routers.minio = {
        rule = "Host(`${builtins.elemAt config.snippets.thein3rovert.networkMap.s3.vHost 1}`)";
        service = "minio";
        entryPoints = [ "websecure" ];
        tls = {
          certResolver = "cloudflare";
        };
      };

    };

  };
}
