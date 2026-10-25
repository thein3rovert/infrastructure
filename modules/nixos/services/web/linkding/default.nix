{
  config,
  lib,
  ...
}:
let

  if-linkding-enable = lib.mkIf config.nixosSetup.services.linkding.enable;
  # create-linkding-containter = virtualisation.oci-containers."linkding";
  # TODO: Common attribute name should be
  # moved to base as shared options
  imageName = "sissbruecker/linkding";
  imageTag = "latest";
  host = "127.0.0.1";
  port = 9090;

  dataVolume = "linkding_data";
in
{
  options.nixosSetup.services.linkding = {
    enable = lib.mkEnableOption "Linkding Bookmarker Service";
  };

  config = if-linkding-enable {
    myContainers.traefik = {
      enable = true;
      defaultEntryPoints = [ "websecure" ];
      defaultCertResolver = "cloudflare";
    };
    myContainers = {
      enable = true;
      containers = {
        linkding = {
          image = "${imageName}:${imageTag}";
          ports = [ "${host}:${toString port}:9090" ];
          volumes = [
            "${dataVolume}:/etc/linkding/data"
          ];
          environment = {
            LD_DISABLE_BACKGROUND_TASKS = "true";
          };
          environmentFiles = [ config.age.secrets.linkding.path ];
          traefik = {
            enable = true;
            url = "http://localhost:9090/";
            rule = "Host(`linkding.thein3rovert.dev`)";
          };

        };
      };
    };
  };
}
