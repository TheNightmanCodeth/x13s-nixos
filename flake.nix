{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    let
      dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./packages/part.nix ];

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

      flake.nixosModules.default = import ./module.nix { inherit dtbName; };

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

        iso = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [

            self.nixosModules.default
            (
              {
                modulesPath,
                config,
                lib,
                pkgs,
                ...
              }:
              let
                image = import "${inputs.nixpkgs}/nixos/lib/make-disk-image.nix" {
                  inherit config lib pkgs;

                  name = "nixos-x13s-bootstrap";
                  diskSize = "auto";
                  format = "raw";
                  partitionTableType = "efi";
                  copyChannel = false;
                };

              in
              {
                hardware.deviceTree = {
                  enable = true;
                  name = "qcom/${dtbName}";
                };

                system.build.bootstrap-image = image;

                boot = {
                  initrd = {
                    systemd.enable = true;
                    systemd.emergencyAccess = true;
                  };

                  loader = {
                    grub.enable = false;
                    systemd-boot.enable = true;
                    systemd-boot.graceful = true;
                  };
                };

                nixpkgs.config.allowUnfree = true;

                nixos-x13s = {
                  enable = true;
                  kernel = "jhovold";
                  bluetoothMac = "02:68:b3:29:da:98";
                  wifiMac = "F4:A8:0D:FF:7C:87";
                };

                fileSystems = {
                  "/boot" = {
                    fsType = "vfat";
                    device = "/dev/disk/by-label/ESP_nixinstaller";
                  };
                  "/" = {
                    device = "/dev/disk/by-label/nixos_nixinstaller";
                    fsType = "ext4";
                    autoResize = true;
                  };
                };
              }
            )
          ];
        };
      };
    };
}
