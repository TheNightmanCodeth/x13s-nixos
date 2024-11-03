{ dtbName, version, graphics-fw, jhovold-src }:
{ 
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.nixos-x13s;

  x13sPackages = import ./packages/default.nix { 
    inherit pkgs version graphics-fw jhovold-src;
  };

  linuxPackages_x13s = pkgs.linuxPackagesFor x13sPackages.jhovold-linux;

  dtb = "${linuxPackages_x13s.kernel}/dtbs/qcom/${dtbName}";
  dtbEfiPath = "dtbs/x13s.dtb";

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
    kernel = config.system.modulesTree;
    firmware = config.hardware.firmware;
    allowMissing = false;
  };

  modulesWithExtra = pkgs.symlinkJoin {
    name = "modules-closure";
    paths = [
      modulesClosure
      x13sPackages.graphics-firmware
    ];
  };
in
{
  options.nixos-x13s = {
    enable = lib.mkEnableOption "X13s hardware support";

    wifiMac = lib.mkOption {
      type = lib.types.str;
      description = "WiFi MAC address to set on boot";
    };

    bluetoothMac = lib.mkOption {
      type = lib.types.str;
      description = "Bluetooth MAC address to set on boot";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.efibootmgr ];

    hardware.enableAllFirmware = true;
    hardware.firmware = lib.mkBefore [ x13sPackages.graphics-firmware ];

    boot = {
      initrd.systemd.enable = true;
      initrd.systemd.contents = {
        "/lib".source = lib.mkForce "${modulesWithExtra}/lib";
      };

      loader.efi.canTouchEfiVariables = true;
      loader.systemdboot.enable = lib.mkDefault true;
      loader.systemdboot.extraFiles = {
        "${dtbEfiPath}" = dtb;
      };

      kernelPackages = linuxPackages_x13s;

      kernelParams = [
        "dtb=${dtbEfiPath}"

        "clk_ignore_unused"
        "pd_ignore_unused"
        "arm64.nopauth"
      ];

      initrd = {
        kernelModules = [
          "nvme"
          "phy_qcom_qmp_pcie"
          "pcie_qcom"
          "i2c_hid_of"
          "i2c_qcom_geni"
          "leds_qcom_lpg"
          "pwm_bl"
          "qrtr"
          "pmic_glink_altmode"
          "gpio_sbu_mux"
          "phy_qcom_qmp_combo"
          "gpucc_sc8280xp"
          "dispcc_sc8280xp"
          "phy_qcom_edp"
          "panel_edp"
          "msm"
        ];
      };
    };

    powerManagement.cpuFreqGovernor = "ondemand";

    # https://github.com/jhovold/linux/wiki/X13s#camera
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="linux,cma", GROUP="video", MODE="0660"
      ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="system", GROUP="video", MODE="0660"
      ACTION=="add", SUBSYSTEM=="net", KERNELS=="0006:01:00.0", RUN+="${pkgs.iproute2}/bin/ip link set dev $name address ${cfg.wifiMac}"
    '';

    systemd.services.bluetooth-x13s-mac = {
      wantedBy = [ "multi-user.target" ];
      before = [ "bluetooth.service" ];
      requiredBy = [ "bluetooth.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.util-linux}/bin/script -q -c '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${cfg.bluetoothMac}'";
      };
    };
  };
}
