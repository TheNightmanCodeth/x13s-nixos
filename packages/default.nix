{ pkgs, version, jhovold-src, graphics-fw, ... }:
{
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

  graphics-firmware = pkgs.runCommand "graphics-firmware" { } ''
    mkdir -vp "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
    ${pkgs.lib.getExe pkgs.innoextract} ${graphics-fw}
    cp -v code\$GetExtractPath\$/*/*.mbn "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX/"
  '';
}
