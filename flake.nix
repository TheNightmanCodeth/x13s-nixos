{
  description = "Nix flake providing linux kernel(s) for thinkpad X13s";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    jhovold = {
      url = "github:jhovold/linux/wip/sc8280xp-6.11-rc7";
      flake = false;
    };
    gpu-fw = {
      url = "https://download.lenovo.com/pccbbs/mobiles/n3hdr20w.exe";
      flake = false;
    };
    linux-fw.url = "github:TheNightmanCodeth/linux-firmware-git-flake/main";
  };

  outputs = { self, nixpkgs, jhovold, gpu-fw, linux-fw, ... }: 
    let
      pkgs = import nixpkgs {
        system = "aarch64-linux";
      };
      linux_jhovold_pkg = { version, ...}@args: pkgs.buildLinux(
        args
        // {
          modDirVersion = version;
          kernelPatches = (args.kernelPatches or [ ]) ++ [ ];
          extraMeta.branch = nixpkgs.lib.versions.majorMinor version;
        }
      );
    in
    {
      packages.aarch64-linux = {
        linux-fw = linux-fw.nixosModules.default;

        linux-jhovold = 
          linux_jhovold_pkg {
            src = jhovold;
            version = "6.11.0-rc7";
            defconfig = "johan_defconfig";
          };

        x13s-gpu-fw = 
          pkgs.runCommand "graphics-firmware" { } ''
            mkdir -vp "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
            ${pkgs.lib.getExe pkgs.innoextract} ${gpu-fw}
            cp -v code\$GetExtractPath\$/*/*.mbn "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
          '';
      };
    };
}

