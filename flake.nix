{
  description = "Linux Kernel for Lenovo Thinkpad X13s";

  inputs = { 
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    graphics-fw = {
      url = "https://download.lenovo.com/pccbbs/mobiles/n3hdr20w.exe";
      flake = false;
    };

    jhovold-src = {
      url = "github:jhovold/linux/wip/sc8280xp-6.12-rc3";
      flake = false;
    };
  };


  outputs = { nixpkgs, jhovold-src, graphics-fw, ... }:
  let
    version = "6.12.0-rc3";
    pkgs = import nixpkgs {
      system = "aarch64-linux";
    };
  in 
  {
    boot.kernelPackages = pkgs.linuxPackages.extend (pkgs.lib.const (super: {
      kernel = super.kernel.overrideDerivation (drv: {
        nativeBuildInputs = (drv.nativeBuildInputs or []) ++ [ pkgs.zlib pkgs.lz4 ];
      });
    }));

    graphics-firmware = pkgs.runCommand "graphics-firmware" { } ''
      mkdir -vp "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
      ${pkgs.lib.getExe pkgs.innoextract} ${graphics-fw}
      cp -v code\$GetExtractPath\$/*/*.mbn "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX/"
    '';

    packages.aarch64-linux.jhovold-linux = pkgs.buildLinux {
      inherit version;
      src = jhovold-src;
      defconfig = "johan_defconfig";
      modDirVersion = version;
      extraMeta.branch = "wip/sc8280xp-${version}";
    };
  };
}
