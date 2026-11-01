{ pkgs, ... }:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObli1unUWlbZaja5VMzTIvPBJOCI/E6vs/qhrVkSHLO"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  users.users.thein3rovert = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObli1unUWlbZaja5VMzTIvPBJOCI/E6vs/qhrVkSHLO thein3rovert"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEIyYYJN/Zy38lnIdx1C1I9kQOtgKQaTt7/bagchFrxN danielolaibi@gmail.com"
    ];
  };
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    python3
  ];

  security.sudo.extraRules = [
    {
      users = [
        "thein3rovert"
        "root"
      ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  security.sudo.wheelNeedsPassword = false;

  nixosSetup = {
    programs = {
      # docker (not podman): gitea-actions-runner `docker://` labels need a
      # Docker daemon socket. See modules/nixos/services/cicd/forgejo-runner.
      docker.enable = true;
    };
    services = {
      tailscale.enable = true;
      forgejo-runner = {
        enable = true;
        dockerContainers = 1;
        nativeRunners = 1;
      };
    };
  };

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  nix.settings = {
    trusted-users = [
      "root"
      "thein3rovert"
    ];
  };

  programs.zsh.enable = true;
  system.stateVersion = "25.05";
}
