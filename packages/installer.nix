{ ... }:
{
  config = {
    nixpkgs.config.allowUnfree = true;

    nixos-x13s.enable = true;
    nixos-x13s.kernel = "jhovold";
    nixos-x13s.bluetoothMac = "F4:A8:0D:2A:84:EA";
    nixos-x13s.wifiMac = "F4:A8:0D:FF:7C:87";
    
    boot.initrd.systemd.tpm2.enable = false;
  };
}

