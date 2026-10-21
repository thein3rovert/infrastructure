# ============================================================================
# HOST-SPECIFIC HOME-MANAGER CONFIG: trikru (Ubuntu 22.04 server, Proxmox VM)
# ============================================================================
# This is a STANDALONE home-manager config (not NixOS integration).
# Activate with: home-manager switch --flake .#thein3rovert@trikru
#
# 📖 See docs: `doc-001 - Home-Manager-Configuration-Architecture.md`
#
# HOW IT'S LOADED:
#   modules/flake/home-manager.nix loads this file AFTER
#   self.homeManagerModules.thein3rovert (the base config), so anything
#   defined here MERGES with / OVERRIDES the base.
#
# ⚠️ DO NOT wrap config in `home-manager.users.thein3rovert = { ... }`.
#    That option only exists in NixOS integration mode. In standalone mode
#    you configure home-manager DIRECTLY at the root level.
#
# TO OVERRIDE A BASE VALUE:
#   Use `lib.mkForce` for scalars (e.g. stateVersion).
#   Lists (like packages) automatically concatenate with the base.
# ============================================================================
{
  pkgs,
  lib,
  self,
  ...
}:
{
  # Host-specific packages (added on top of base packages from default.nix)
  home.packages = with pkgs; [
    vim
    obsidian-headless
  ];

  # Tools installed outside nix (e.g. Hermes agent harness in ~/.local/bin)
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Override base stateVersion (base = "25.11", this host = "25.05")
  home.stateVersion = lib.mkForce "25.05";

  # Enable zsh for this host
  programs.zsh.enable = true;

  # Enable Obsidian sync service
  homeSetup.systemd.ob-sync = {
    enable = true;
    vaultPath = "/home/thein3rovert/vault/thein3rovert-brain";
  };

  # Enable Opencode Web Interface
  homeSetup.systemd.opencode-web = {
    enable = true;
    port = 3000;
    hostname = "0.0.0.0";
  };

  homeSetup.programs = {
    # Main opencode config
    opencode = {
      enable = true;
      extraSettings = {
        provider = {
          opencode-go = {
            models = {
              "opencode-go/deepseek-v4-flash" = {
                name = "deepseek-v4-flash";
              };
            };
          };
          # github-copilot = {
          #   models = {
          #     "gpt-4.1" = {
          #       name = "GPT-4.1";
          #       limit = {
          #         context = 128000;
          #         output = 16384;
          #       };
          #       modalities = {
          #         input = [ "text" ];
          #         output = [ "text" ];
          #       };
          #     };
          # "claude-sonnet-4-5" = {
          #   name = "Claude Sonnet 4.5";
          # limit = {
          #   context = 128000;
          #   output = 16000;
          # };
          # modalities = {
          #   input = [ "text" ];
          #   output = [ "text" ];
          # };
          # };
          #   };
          # };
        };
      };
    };

    # Opencode agent config
    # This is independent of the agent config
    agent = {
      enable = true;
      agentsInput = self.inputs.polis;

      opencode = {
        enable = true;
        agentsInput = self.inputs.polis;
        modelOverrides = {
          ag-quick-chat = "opencode-go/deepseek-v4-flash";
          # ag-blog-writer = "anthropic/claude-sonnet-4";
        };
      };
    };
  };
}
