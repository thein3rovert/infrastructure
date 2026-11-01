{
  description = ''
    This is a configuration for managing multiple nixos machines
  '';

  # ================================
  #         FLAKE INPUTS
  # ================================
  inputs = {
    # Age-based secret management
    agenix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:yaxitech/ragenix";
    };

    # Clan core for machine management
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Test
    # Deployment tool for NixOS machines
    colmena.url = "github:zhaofengli/colmena";

    # deploy-rs — flake-based multi-profile deploy tool (used for HM-only hosts)
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake parts for modular flake organization
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Ghostty terminal emulator
    # ghostty = {
    #   url = "github:ghostty-org/ghostty";
    # };

    # Home Manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Color scheme management
    nix-colors.url = "github:misterio77/nix-colors";

    # Main nixpkgs repository (unstable channel)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Smaller unstable channel for faster updates
    # INFO: Breaking changes removing for now
    # nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    # Private secrets repository
    secrets = {
      url = "github:thein3rovert/secret-vault";
      flake = false;
    };

    # TODO: Fix SSH authentication for private polis repo in CI
    # Agent definitions and coding rules
    polis = {
      # url = "path:/home/m3tam3re/p/AI/AGENTS";
      url = "git+ssh://git@github.com/thein3rovert/polis.git";
      # flake = false; # Now a proper flake!
    };

    # Zen browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Arkadia library framework
    arkadia = {
      url = "github:thein3rovert/arkadia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flox - Dev environment manager
    flox = {
      url = "github:flox/flox/latest";
    };

    # Backlog.md - Task management tool
    backlog-md = {
      url = "github:MrLesk/Backlog.md";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://thein3rovert.cachix.org"
      "https://cache.flox.dev"
    ];
    extra-trusted-public-keys = [
      "thein3rovert.cachix.org-1:gvwn/ed5w81ylC4IgBrHEvypkAybKaDlg2zdSbmyJ+o="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  outputs =
    {
      self,
      agenix,
      arkadia,
      clan-core,
      colmena,
      deploy-rs,
      disko,
      flake-parts,
      home-manager,
      nix-colors,
      nixpkgs,
      # nixpkgs-unstable-small,
      zen-browser,
      polis,
      # ghostty,
      ...
    }@inputs:
    let
      # Initialize Arkadia library
      arkadia-lib = arkadia.mkLib {
        inherit inputs;
        src = ./.;
        arkadia.namespace = "nixos-config";
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # ================================
      #      FLAKE PART CONFIG
      # ================================
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Import flake modules
      imports = [
        ./modules/flake
      ];

      flake =
        let
          inherit (self) outputs;

          # ================================
          #      SYSTEM DEFINITIONS
          # ================================
          allSystems = [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-darwin"
            "x86_64-linux"
            # NOTE: i686-linux excluded due to agenix compatibility issues
          ];

          # ================================
          #      HELPER FUNCTIONS
          # ================================
          # Defines a function called 'forAllSystems' that takes a function 'f' as an argument
          forAllSystems =
            f:
            # Calls 'genAttrs' from nixpkgs' lib to generate an attribute set for all systems in 'allSystems'
            self.inputs.nixpkgs.lib.genAttrs allSystems (
              system:
              # For each system, call the function 'f' with a set containing 'pkgs'
              f {
                # 'pkgs' is Nixpkgs imported for the current system, with overlays and unfree packages allowed
                pkgs = import self.inputs.nixpkgs {
                  inherit system;
                  config.allowUnfree = true;
                };
              }
            );

          # Helper function to generate configurations for all Linux hosts
          forAllLinuxHosts = self.inputs.nixpkgs.lib.genAttrs [
            "bellamy"
            "nixos"
            "marcus"

            # Managed by Proxmox
            "finn" # (Lxc - Killed by grounders)
            "roan" # lxc for all current container on emily
            "zeke" # lxc - technitium dns resolver
            "forgejo-runner" # lxc - Forgejo Actions runners (HML-054)
            # "vps-het-1"
            # "demo"
            # "wellsjaha"

            # Managed by incus
            # "lexa" (LXC)

            # Managed by clan
            # "octavia"
          ];
        in
        {
          # ================================
          #      EXTENDED LIB WITH TYPES
          # ================================
          lib = nixpkgs.lib.extend (
            final: prev: {
              t = import ./modules/nixos/os/profiles/types/lib/types.nix { lib = final; };
              arkadia = arkadia-lib.arkadia;
            }
          );

          # ================================
          #      NIXOS CONFIGURATIONS
          # ================================
          nixosConfigurations = forAllLinuxHosts (
            host:
            self.inputs.nixpkgs.lib.nixosSystem {
              specialArgs = {
                inherit
                  self
                  inputs
                  nix-colors
                  colmena
                  # nixpkgs-unstable-small
                  arkadia-lib
                  ;
                lib = self.lib;
              };

              modules = [
                # Host-specific configuration
                ./hosts/${host}

                # Core system modules
                agenix.nixosModules.default
                inputs.disko.nixosModules.disko
                self.inputs.home-manager.nixosModules.home-manager

                # Custom modules
                self.nixosModules.base

                self.nixosModules.core
                self.nixosModules.hardware
                self.nixosModules.nixosOs
                self.nixosModules.snippets
                self.nixosModules.tools # <-- New: cowsay and jq
                self.nixosModules.users

                # Overlays
                {
                  nixpkgs.overlays = [ self.overlays.default ];
                }

                # Additional packages
                {
                  environment.systemPackages = [
                    # ghostty.packages.x86_64-linux.default
                    agenix.packages.x86_64-linux.default
                  ];
                }

                # ---- Home-Manager Config ----
                {
                  home-manager = {
                    backupFileExtension = "backup";
                    extraSpecialArgs = { inherit self inputs arkadia-lib; };
                    useGlobalPkgs = true;
                    useUserPackages = true;
                  };
                  nixpkgs = {
                    config.allowUnfree = true;
                  };
                }
              ];
            }
          );

          # ============================================
          #        NIXOS MODULES and ARKADIA MODULES
          # ============================================
          nixosModules =
            let
              # Auto-discover only tools module
              /*
                Dont want to point to nixos/modules as it containers
                manual important modules for now.
                TODO: Migrate later on when confident
              */
              all-auto-modules = arkadia-lib.arkadia.module.create-modules {
                src = ./modules/arkadia/development;
              };
              # auto-modules = {
              #   tools = all-auto-modules.tools;
              # };
            in
            all-auto-modules # Merge arkadia modules into manual modules
            // {
              # Manual modules
              base = ./modules/base;
              core = ./modules/core;
              hardware = ./modules/hardware;
              locale-en-uk = ./modules/nixos/profiles/locale/en-uk;
              nixosOs = ./modules/nixos;
              snippets = ./modules/snippets;
              users = ./modules/nixos/users;
            };

          # ================================
          #           OVERLAYS
          # ================================
          # overlays = import ./overlays { inherit inputs; };

          # ================================
          #    COLMENA DEPLOYMENT CONFIG
          # ================================
          colmenaHive = colmena.lib.makeHive {
            # Global configuration for all nodes
            meta = {
              nixpkgs = import nixpkgs {
                system = "x86_64-linux";
              };
              specialArgs = {
                inherit
                  self
                  inputs
                  nix-colors
                  arkadia-lib
                  ;
              };
            };

            # ---- Node: Bellamy (Prod) ----
            bellamy = {
              deployment = {
                targetHost = "bellamy";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [
                  "prod"
                  "production"
                  "vps"
                ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/bellamy
                agenix.nixosModules.default
                inputs.disko.nixosModules.disko
                self.inputs.home-manager.nixosModules.home-manager
                self.nixosModules.base

                self.nixosModules.nixosOs
                self.nixosModules.snippets
                self.nixosModules.users
              ];
            };

            # ---- Node: Marcus (Prod) ----
            marcus = {
              deployment = {
                targetHost = "100.94.20.21";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [
                  "prod"
                  "production"
                  "bare-metal"
                ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/marcus
                self.inputs.home-manager.nixosModules.home-manager
                # self.homeManagerModules.default
                agenix.nixosModules.default
                self.nixosModules.nixosOs
                self.nixosModules.base
                # For services
                self.nixosModules.snippets

                {
                  nixpkgs.overlays = [ self.overlays.default ];
                }
                {
                  home-manager = {
                    backupFileExtension = "backup";
                    extraSpecialArgs = { inherit self inputs; };
                    useGlobalPkgs = true;
                    useUserPackages = true;
                  };
                  nixpkgs = {
                    config.allowUnfree = true;
                  };
                }
              ];
            };

            # ---- Node: Demo ----
            demo = {
              deployment = {
                targetHost = "demo";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [ "homelab" ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/demo
                inputs.disko.nixosModules.disko
                self.nixosModules.nixosOs
              ];
            };

            # ---- Node: Finn [ lxc 02 ] ----
            finn = {
              deployment = {
                targetHost = "192.168.0.51";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = false;
                tags = [ "homelab" ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/finn
                agenix.nixosModules.default
                self.nixosModules.base
                self.inputs.home-manager.nixosModules.home-manager

                self.nixosModules.nixosOs
              ];
            };
            # ---- Node: Roan [ lxc 03] ----
            roan = {
              deployment = {
                targetHost = "192.168.0.103";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = false;
                tags = [ "homelab" ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/roan
                agenix.nixosModules.default
                self.nixosModules.base
                self.nixosModules.snippets
                # self.inputs.home-manager.nixosModules.home-manager
                self.nixosModules.nixosOs
              ];
            };

            # ---- Node: Zeke [ lxc 04 ] ----
            zeke = {
              deployment = {
                targetHost = "192.168.0.106";
                targetPort = 22;
                targetUser = "root";
                buildOnTarget = false;
                tags = [ "homelab" ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/zeke
                agenix.nixosModules.default
                self.nixosModules.base
                self.nixosModules.snippets
                self.nixosModules.nixosOs
              ];
            };

            # ---- Node: Forgejo Runner [ lxc 104 ] ----
            forgejo-runner = {
              deployment = {
                targetHost = "192.168.0.104";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = false;
                tags = [
                  "homelab"
                  "ci"
                ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/forgejo-runner
                agenix.nixosModules.default
                self.nixosModules.base
                self.nixosModules.snippets
                self.nixosModules.nixosOs
              ];
            };

            # ---- Node: Runner [ lxc 02 ] ----
            nixos-runner = {
              deployment = {
                targetHost = "nixos-runner";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [
                  "prod"
                  "runner"
                ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/runner
                agenix.nixosModules.default
                self.nixosModules.users

                self.nixosModules.nixosOs
                self.nixosModules.snippets
              ];
            };

            # ---- Node: Lexa [ proxmox-lxc 01 ] ----
            lexa = {
              deployment = {
                targetHost = "10.135.108.10";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [ "test" ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/lexa
                agenix.nixosModules.default
                self.nixosModules.users

                self.nixosModules.nixosOs
                self.nixosModules.snippets
                self.inputs.home-manager.nixosModules.home-manager
              ];
            };

            # ---- Node: Octavia (Prod) ----
            octavia = {
              deployment = {
                targetHost = "octavia";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [
                  "prod"
                  "test"
                ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/octavia
                agenix.nixosModules.default
                inputs.disko.nixosModules.disko
                self.inputs.home-manager.nixosModules.home-manager
                self.nixosModules.base
                self.nixosModules.hardware
                self.nixosModules.nixosOs
                self.nixosModules.users
                self.nixosModules.snippets
              ];
            };

            # ---- Node: VPS-HET-1 ----
            vps-het-1 = {
              deployment = {
                targetHost = "vps-het-1";
                targetPort = 22;
                targetUser = "thein3rovert-cloud";
                buildOnTarget = true;
                tags = [
                  "production"
                  "vps"
                ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/vps-het-1
                agenix.nixosModules.default
                inputs.disko.nixosModules.disko
                self.inputs.home-manager.nixosModules.home-manager
                self.nixosModules.nixosOs
              ];
            };

            # ---- Node: Wellsjaha (Test) ----
            wellsjaha = {
              deployment = {
                targetHost = "wellsjaha";
                targetPort = 22;
                targetUser = "thein3rovert";
                buildOnTarget = true;
                tags = [ "test" ];
              };
              nixpkgs.system = "x86_64-linux";
              imports = [
                ./hosts/wellsjaha
                agenix.nixosModules.default
                inputs.disko.nixosModules.disko
                self.inputs.home-manager.nixosModules.home-manager
                self.nixosModules.base

                self.nixosModules.hardware
                self.nixosModules.nixosOs
                self.nixosModules.snippets
                self.nixosModules.users
              ];
            };
          };
        };
    };
}
