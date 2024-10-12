{ lib, withSystem, jhovold-linux, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        uefi = pkgs.callPackage ./uefi.nix { };
        uefi-usbiso = pkgs.callPackage ./uefi-usbiso.nix { inherit uefi; };
      };
    };

  flake.packages.aarch64-linux = withSystem "aarch64-linux" (
    { pkgs, jhovold-linux, ... }: import ./default.nix { inherit lib pkgs jhovold-linux; }
  );
}
