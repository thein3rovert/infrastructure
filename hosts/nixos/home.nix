# ==============================
#    Home Manager Configuration
# ==============================
# Home Manager configuration for the nixos host
# Manages user environment and dotfiles

{
  self,
  inputs,
  lib,
  config,
  ...
}:
let
  # ==============================
  #      Module Definitions
  # ==============================
  # Custom flake modules
  customImport = self.homeManagerModules.default;
  # kittyConfig = ../../modules/home/thein3rovert/programs/kitty;

  # ==============================
  #      SSH Configuration
  # ==============================
  # Default SSH settings applied to all hosts
  defaultSSHConfig = {
    forwardAgent = false;
    controlMaster = "no";
    userKnownHostsFile = "~/.ssh/known_hosts";
    compression = false;
    serverAliveCountMax = 3;
    serverAliveInterval = 0;
    controlPath = "~/.ssh/master-%r@%n:%p";
    controlPersist = "no";
    hashKnownHosts = false;
    addKeysToAgent = "no";
    identitiesOnly = true; # Stop load all keys from .ssh
  };
in
{
  # ==============================
  #      Home Manager Setup
  # ==============================
  home-manager.users.thein3rovert =
    { pkgs, ... }:
    {
      # ==============================
      #         Module Imports
      # ==============================
      imports = [
        customImport
        # kittyConfig
        self.inputs.zen-browser.homeModules.beta
      ];

      # ==============================
      #      Home Configuration
      # ==============================
      home = {
        # User identity
        username = lib.mkDefault "thein3rovert";
        homeDirectory = lib.mkDefault "/home/${config.home.username}";

        # User packages
        packages = with pkgs; [
          # System monitoring and utilities
          btop # Resource monitor

          # Development and editing
          zed-editor # Modern text editor
          kitty # Terminal emulator

          # Desktop environment tools
          wofi # Application launcher
          wlogout # Logout menu
          hyprlock # Screen locker
          waybar # Status bar (configured separately)

          # Hardware control
          blueman # Bluetooth manager
          # pavucontrol # Audio control
          pwvucontrol
          playerctl # Media player control
          brightnessctl # Brightness control

          # Fun utilities
          cowsay # ASCII art messages
        ];

        # Home Manager state version
        stateVersion = "24.05";
      };

      home.sessionVariables = {
        #   AWS_ACCESS_KEY_ID = "$(sudo cat ${config.age.secrets.garage_thein3rovert_id.path} )";
        #   AWS_SECRET_ACCESS_KEY = "$(cat ${config.age.secrets.garage_thein3rovert_secret.path})";
        AWS_DEFAULT_REGION = "garage";
        AWS_ENDPOINT_URL = "http://localhost:3900";
        AWS_PROFILE = "garage";
      };

      # };

      # ==============================
      #      Cursor Configuration
      # ==============================
      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.banana-cursor;
        name = "Banana";
        size = 24;
      };
      # ==============================
      #      Program Configuration
      # ==============================
      # Core programs
      programs.home-manager.enable = true;
      programs.waybar.enable = true;

      programs.zen-browser = {
        enable = true;
        # suppressXdgMigrationWarning = true;  # Migration is done and not needed anymore
      };
      # nativeMessagingHosts = lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-desktop ];
      # package = lib.mkIf pkgs.stdenv.isDarwin (lib.mkForce null);
      # ==============================
      #       SSH Configuration
      # ==============================
      programs.ssh = {
        enableDefaultConfig = false;
        enable = true;
        matchBlocks = {
          # Demo/development server
          demo = lib.recursiveUpdate defaultSSHConfig {
            hostname = "192.168.122.36";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
          };

          # GitHub repository access
          "github.com" = lib.recursiveUpdate defaultSSHConfig {
            hostname = "github.com";
            identityFile = "~/.ssh/github/thein3rovert_github";
            user = "git";
          };

          # =================
          # Test servers
          # =================
          wellsjaha = lib.recursiveUpdate defaultSSHConfig {
            hostname = "10.20.0.1";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
          };
          lexa = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.88.29.64";
            identityFile = "~/.ssh/thein3rovert_nixos";
            user = "thein3rovert";
          };

          # ================
          # PRODUCTION
          # ================

          # Production VPS
          # INFO: Using custom ssh key for reproducibility
          bellamy = lib.recursiveUpdate defaultSSHConfig {
            hostname = "95.216.216.22";
            identityFile = "~/.ssh/thein3rovert_nixos";
            user = "thein3rovert";
          };
          roan = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.99.235.113";
            identityFile = "~/.ssh/thein3rovert_nixos";
            user = "thein3rovert";
          };
          forgejo-runner = lib.recursiveUpdate defaultSSHConfig {
            hostname = "192.168.0.104";
            identityFile = "~/.ssh/thein3rovert_nixos";
            user = "thein3rovert";
          };
          nightblood = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.77.212.11";
            identityFile = "~/.ssh/id_ed25519";
            user = "root";
          };
          zeke = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.74.26.17";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
          };
          finn = lib.recursiveUpdate defaultSSHConfig {
            hostname = "192.168.0.51";
            identityFile = "~/.ssh/thein3rovert_nixos";
            user = "thein3rovert";
          };
          lincoln = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.87.231.18";
            identityFile = "~/.ssh/id_ed25519";
            user = "root";
          };
          raven = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.123.5.107";
            identityFile = "~/.ssh/id_ed25519";
            user = "root";
          };
          trikru = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.118.122.19";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
          };
          k3s-server = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.85.190.19";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
          };
          becca = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.123.31.22";
            identityFile = "~/.ssh/id_ed25519";
            user = "root";
          };
          runner = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.87.59.51";
            identityFile = "~/.ssh/id_ed25519";
            user = "root";
          };
          marcus = lib.recursiveUpdate defaultSSHConfig {
            hostname = "100.94.20.21";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
          };
          nixos-runner = lib.recursiveUpdate defaultSSHConfig {
            hostname = "10.10.20.10";
            identityFile = "~/.ssh/id_ed25519";
            user = "thein3rovert";
            proxyJump = "marcus";
          };
        };
      };

      # ==============================
      #      Custom Module Setup
      # ==============================
      homeSetup = {
        # TODO: Move later to Arkadia home modules
        # can call from arkadia instead
        programs.backlog-md.enable = true;
        programs.fzf.enable = true;

        thein3rovert = {
          programs.apps.enable = true;
          programs.cli.enable = true;
          programs.git.enable = true;
          programs.zsh.enable = true;
          programs.kitty.enable = true;
          programs.starship.enable = true;
          programs.gtk.enable = true;
          programs.dunst.enable = true;
        };
      };

      # ==============================
      #      Nix Configuration
      # ==============================
      nix = {
        package = lib.mkDefault pkgs.nix;

        # Nix settings and features
        settings = {
          experimental-features = "nix-command flakes";
          trusted-users = [
            "root"
            "thein3rovert"
          ];
        };

        # Garbage collection
        gc = {
          automatic = true;
          options = "--delete-older-than 30d";
        };

        # Flake registry setup
        registry = lib.mapAttrs (_: flake: { inherit flake; }) (
          lib.filterAttrs (_: lib.isType "flake") inputs
        );

        # Custom NIX_PATH
        nixPath = [ "/etc/nix/path" ];
      };
    };
}
