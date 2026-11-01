{
  config,
  lib,
  pkgs,
  self,
  ...
}:
{
  # Define the options for this module so other configs can enable/configure it
  options.nixosSetup.services.forgejo-runner = {
    enable = lib.mkEnableOption "Forĝejo runners";
    # How many native NixOS runners (run jobs directly on the host)
    nativeRunners = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "How many native NixOS runners to run for the Forĝejo runner.";
    };
    # How many Docker-based runners (run jobs inside containers)
    dockerContainers = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "How many docker containers to run for the Forĝejo runner.";
    };
  };

  # Only apply this config if the module is enabled
  config = lib.mkIf config.nixosSetup.services.forgejo-runner.enable {

    # Ensure Tailscale is enabled since Forgejo is accessed over the Tailnet
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "We contact Forĝejo over tailscale, but services.tailscale.enable != true.";
      }
    ];

    # age.secrets.forgejo-runner.file = "${self.inputs.secrets}/forgejo/runner/forgejo-runner-secret.age";

    services.gitea-actions-runner =
      let
        # Normalize arch name e.g. "x86_64-linux" -> "x86_64_linux"
        arch = lib.replaceStrings [ "-" ] [ "_" ] pkgs.stdenv.hostPlatform.system;
      in
      {
        instances =
          let
            # Path to the runner token secret (managed by agenix)
            tokenFile = config.age.secrets.forgejo-runner.path;
          in
          {
            # Runner 1: Docker-based runner — runs CI jobs inside Docker containers
            thein3rovert-containers = {
              inherit tokenFile;
              enable = true;
              # Pick the right Docker image based on architecture
              labels =
                lib.optional (arch == "aarch64_linux") "ubuntu-24.04-arm:docker://gitea/runner-images:ubuntu-latest"
                ++ lib.optional (arch == "x86_64_linux") "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest";
              name = "${arch}-${config.networking.hostName}-thein3rovert-containers";
              settings = {
                container.network = "host"; # containers share host network
                runner.capacity = config.nixosSetup.services.forgejo-runner.dockerContainers;
              };
              # Connect to your Forgejo instance over Tailscale
              # url = "http://${config.myDns.networkMap.localNetworkMap.forgejo.hostName}:${toString config.myDns.networkMap.localNetworkMap.forgejo.port}";
              url = "http://100.105.187.63:${toString config.myDns.networkMap.localNetworkMap.forgejo.port}";
            };

            # Runner 2: Native NixOS runner — runs CI jobs directly on the host
            thein3rovert-nixos = {
              inherit tokenFile;
              enable = true;
              # Tools available to jobs running natively
              hostPackages =
                with pkgs;
                [
                  bash
                  cachix
                  coreutils
                  curl
                  gawk
                  gitMinimal
                  gnused
                  jq
                  nodejs
                  wget
                ]
                ++ [ config.nix.package ]; # include nix itself for nix builds
              labels = [ "nixos-${arch}:host" ]; # label so jobs can target this runner
              name = "${arch}-${config.networking.hostName}-thein3rovert-nixos";
              settings = {
                container.network = "host";
                runner.capacity = config.nixosSetup.services.forgejo-runner.nativeRunners;
              };

              url = "http://100.105.187.63:3002";
            };

            # Runner 3: Privileged builder — image builds needing the host
            # Docker socket. Scoped to the `ci-builder` label: only trusted
            # repos (e.g. forgejo-runner-images) may use it, since socket
            # access is root-equivalent on the runner host.
            # BOOTSTRAP: `ci-runner` image must be pushed once manually
            # (PUSH=1 ./build.sh) before this label works.
            thein3rovert-builder = {
              inherit tokenFile;
              enable = true;
              labels = [ "ci-builder:docker://ghcr.io/thein3rovert/ci-runner:latest" ];
              name = "${arch}-${config.networking.hostName}-thein3rovert-builder";
              settings = {
                container.network = "host";
                container.options = "-v /var/run/docker.sock:/var/run/docker.sock";
                runner.capacity = 1;
              };

              url = "http://100.105.187.63:3002";
            };
          };
      };
  };
}
