{
  config,
  lib,
  ...
}:
let
  if-kestra-enable = lib.mkIf config.nixosSetup.services.kestra.enable;

  imageName = "kestra/kestra:${imageTag}";
  imageTag = "latest";
  port = config.homelab.containerPorts.kestra;

  # Kestra volumes
  dataVolume = "/var/lib/kestra/data:/app/storage";
  dockerVolume = "/var/run/podman/podman.sock:/var/run/docker.sock";
  tmpVolume = "/tmp/kestra-wd:/tmp/kestra-wd";
  configVolume = "/var/lib/kestra/config.yaml:/app/config.yaml:ro";
in
{
  options.nixosSetup.services.kestra = {
    enable = lib.mkEnableOption "Kestra Workflow Orchestration";
  };

  config = if-kestra-enable {
    virtualisation.oci-containers.containers = {
      kestra-controller = {
        image = imageName;
        ports = [ "50051:50051" ];
        volumes = [ dataVolume tmpVolume configVolume ];
        user = "root";
        cmd = [ "server" "controller" "--config" "/app/config.yaml" ];
        extraOptions = [
          "--memory=1024m"
          "--memory-swap=1024m"
          "--restart=on-failure"
        ];
      };
      kestra-executor = {
        image = imageName;
        volumes = [ dataVolume dockerVolume tmpVolume configVolume ];
        user = "root";
        cmd = [ "server" "executor" "--config" "/app/config.yaml" ];
        extraOptions = [
          "--memory=1024m"
          "--memory-swap=1024m"
          "--restart=on-failure"
        ];
      };
      kestra-scheduler = {
        image = imageName;
        volumes = [ dataVolume tmpVolume configVolume ];
        user = "root";
        cmd = [ "server" "scheduler" "--config" "/app/config.yaml" ];
        extraOptions = [
          "--memory=1024m"
          "--memory-swap=1024m"
          "--restart=on-failure"
        ];
      };
      kestra-webserver = {
        image = imageName;
        ports = [
          "${toString port}:8080"
          "8081:8081"
        ];
        volumes = [ dataVolume tmpVolume configVolume ];
        user = "root";
        cmd = [ "server" "webserver" "--config" "/app/config.yaml" ];
        extraOptions = [
          "--memory=3072m"
          "--memory-swap=3072m"
          "--health-cmd=curl -f http://localhost:8081/health || exit 1"
          "--health-interval=30s"
          "--health-retries=3"
          "--health-start-period=60s"
          "--restart=on-failure"
        ];
      };
    };
  };
}
