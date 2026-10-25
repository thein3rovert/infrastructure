{ pkgs, ... }:
{
  #TODO: CONFIGURE AUTO CLEAN NIX CACHE

  # home-manager = {
  #   useUserPackages = true;
  #   useGlobalPkgs = true;
  #   users.thein3rovert = ./home.nix;
  #   backupFileExtension = "backup";
  # };

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
    ];
    # Add ssh keys
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObli1unUWlbZaja5VMzTIvPBJOCI/E6vs/qhrVkSHLO thein3rovert"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEiYYJN/Zy38lnIdx1C1I9kQOtgKQTaTt7/bagchFrxN danielolaibi@gmail.com"
    ];
  };
  environment.systemPackages = with pkgs; [
    vim
    tcpdump
    htop
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
      podman.enable = true;
      fossflow.enable = true;
    };
    services = {
      tailscale.enable = true;
      dockhand.enable = true;
      grafana.enable = true;
      vector.enable = true; # ships journald to local Loki (HML-040.03)
      termix.enable = true;
      kaneo.enable = true;
      dbpro-studio.enable = true;
      # Nightblood NFS is retired. Keep backup data, but do not run jobs
      # against missing sources or block Roan startup on that share.
      zerobyte.enable = false;
    };
  };

  # Add to your LXC's NixOS config
  networking.firewall = {
    enable = true;
    checkReversePath = "loose"; # Use "loose" instead of false
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  nix.settings = {
    sandbox = false;
    trusted-users = [
      "root"
      "thein3rovert"
    ];
  };

  # services.resolved = {
  #   enable = true;
  #   settings = {
  #     Resolve = {
  #       DNSStubListener = "no";
  #     };
  #   };
  # };

  programs.zsh.enable = true;
  system.stateVersion = "25.05";
}
