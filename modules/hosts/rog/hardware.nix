{...}: {
  flake.modules.nixos-rog.hardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];

    boot.kernelModules = [
      "kvm-amd"
      "asus-armoury"
      "hid-asus-rog"
    ];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/1b15a40c-5d10-4d69-9ab7-8021e47b1859";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/34AB-3F48";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/82081385-f916-4753-9646-96bb1e2d313f";}
    ];

    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    services.udev.extraRules = let
      bash = "${pkgs.bash}/bin/bash";
      ddcciDev = "AUX USBC4/DDI TC4/PHY TC4";
    in ''
      SUBSYSTEM=="i2c", ACTION=="add", ATTR{name}=="${ddcciDev}", \
        RUN+="${bash} -c '(sleep 30; printf ddcci 0x37 > /sys%p/new_device) &'"
    '';
  };
}
