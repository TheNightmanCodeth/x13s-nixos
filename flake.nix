{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jhovold-linux = {
      url = "github:jhovold/linux/wip/sc8280xp-6.12-rc4";
      flake = false;
    };
  };

  outputs = { self, jhovold-linux, nixpkgs, ... }:
    let
      dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
    in {
      nixosModules.default = import ./module.nix { 
        inherit dtbName; 
        jhovold-linux = jhovold-linux; 
      };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit dtbName jhovold-linux; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          self.nixosModules.default
          ./packages/installer.nix
        ];
      };

      packages.aarch64-linux.installer = self.nixosConfigurations.installer.config.system.build.isoImage;
    };
}

  #      flake.nixosConfigurations = {
  #        example = inputs.nixpkgs.lib.nixosSystem {
  #          system = "aarch64-linux";
  #          modules = [
  #            self.nixosModules.default
  #            (
  #              { config, pkgs, ... }:
  #              {
  #                nixos-x13s.enable = true;
  #                nixos-x13s.kernel = "jhovold"; # jhovold is default, but mainline supported
  #
  #                # allow unfree firmware
  #                nixpkgs.config.allowUnfree = true;
  #
  #                # define your fileSystems
  #                fileSystems."/".device = "/dev/notreal";
  #              }
  #            )
  #          ];
  #        };
  #      };
  #    };
  #  }
