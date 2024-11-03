{
  description = "Linux Kernel for Lenovo Thinkpad X13s";

  inputs = { 
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    graphics-fw = {
      url = "https://download.lenovo.com/pccbbs/mobiles/n3hdr20w.exe";
      flake = false;
    };

    jhovold-src = {
      url = "github:jhovold/linux/wip/sc8280xp-6.12-rc5";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, jhovold-src, graphics-fw, ... }:
  let
    version = "6.12.0-rc5";
    dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
    pkgs = import nixpkgs {
      system = "aarch64-linux";
    };
  in 
  {
    nixosModules.default = import ./module.nix { inherit dtbName version graphics-fw jhovold-src; };
      
    packages.aarch64-linux = {
      graphics-firmware = pkgs.runCommand "graphics-firmware" { } ''
        mkdir -vp "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
        ${pkgs.lib.getExe pkgs.innoextract} ${graphics-fw}
        cp -v code\$GetExtractPath\$/*/*.mbn "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX/"
      '';

      jhovold-linux = pkgs.buildLinux {
        inherit version;
        src = jhovold-src;
        defconfig = "johan_defconfig";
        modDirVersion = version;
        extraMeta.branch = "wip/sc8280xp-${version}";
        kernelPatches = [
          {
      name = "drm-panic-qr-code-fix";
            patch = pkgs.fetchpatch {
              url = "https://lore.kernel.org/all/20241003230734.653717-1-ojeda@kernel.org/raw";
              hash = "sha256-NH2yz9vzsPgMSuWrrvhJawQxXfFM1KR5c/o2Cnl55XY=";
            };
          }
        ];
        
        #structuredExtraConfig = {
        #  DRM_PANIC_SCREEN_QR_CODE = mkForce no;
        #};
      };

      default = self.packages.aarch64-linux.jhovold-linux;
    };
  };
}
