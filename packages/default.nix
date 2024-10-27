{ lib, pkgs, ... }:
let
  sources = import ../npins;

  linux_x13s_pkg =
    { version, buildLinux, ... }@args:
    buildLinux (
      args
      // {
        modDirVersion = version;

        kernelPatches = (args.kernelPatches or [ ]) ++ [ 
          {
            name = "drm-panic-qr-code-fix";
            patch = pkgs.fetchpatch {
              url = "https://lore.kernel.org/all/20241003230734.653717-1-ojeda@kernel.org/raw";
              hash = "sha256-NH2yz9vzsPgMSuWrrvhJawQxXfFM1KR5c/o2Cnl55XY=";
            };
          }
        ];
        extraMeta.branch = lib.versions.majorMinor version;
      }
    );
in
{
  linux_jhovold = pkgs.callPackage linux_x13s_pkg {
    src = sources.linux-jhovold;
    version = "6.12.0-rc4";
    defconfig = "johan_defconfig";
  };

  graphics-firmware =
    let
      gpu-src = pkgs.fetchurl {
        url = "https://download.lenovo.com/pccbbs/mobiles/n3hdr20w.exe";
        hash = "sha256-Jwyl9uKOnjpwfHd+VaGHjYs9x8cUuRdFCERuXqaJwEY=";
      };
    in
    pkgs.runCommand "graphics-firmware" { } ''
      mkdir -vp "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
      ${lib.getExe pkgs.innoextract} ${gpu-src}
      cp -v code\$GetExtractPath\$/*/*.mbn "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX/"
    '';
}
