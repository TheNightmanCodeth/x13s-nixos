{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    jhovold-linux = {
      url = "github:jhovold/linux/wip/sc8280xp-6.12-rc2";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, self, jhovold-linux, ... }:
    let
      dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
        # imports = [ ./packages/part.nix ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, ... }:
        {
          devShells = rec {
            default = pkgs.mkShellNoCC { packages = [ pkgs.npins ] ++ ci.nativeBuildInputs; };

            ci = pkgs.mkShellNoCC {
              packages = [
                pkgs.cachix
                pkgs.jq
                pkgs.just
                (pkgs.python3.withPackages (py: [
                  py.PyGithub
                  py.packaging
                ]))
                pkgs.pyright
              ];
            };
          };
        };

      flake.nixosModules.default = import ./module.nix { inherit dtbName; jhovold-linux = inputs.jhovold-linux; };

      flake.nixosConfigurations = {
        example = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            self.nixosModules.default
            (
              { config, pkgs, ... }:
              {
                nixos-x13s.enable = true;
                nixos-x13s.kernel = "jhovold"; # jhovold is default, but mainline supported

                # allow unfree firmware
                nixpkgs.config.allowUnfree = true;

                # define your fileSystems
                fileSystems."/".device = "/dev/notreal";
              }
            )
          ];
        };
      };
    };
  }
