{...}: {
  flake.modules.nixos-thinkpad.hardware = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];

    boot = {
      initrd = {
        availableKernelModules = ["thunderbolt"];
        luks.devices."nix-root".device = "/dev/disk/by-uuid/6d5a2cda-e515-427f-87cc-e447d3190324";
      };
      kernelModules = ["kvm-intel"];
      resumeDevice = "/dev/mapper/nix-root";
      kernelParams = ["resume_offset=166780928"];
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/2e353142-2989-4e6b-9b61-8719e3de5b4a";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/6599-8DB7";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };

    swapDevices = [
      {
        device = "/swapfile";
        size = 36864;
        priority = 20;
      }
    ];

    hardware = {
      sensor.iio.enable = true;
      intel-gpu-tools.enable = true;
      cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  };
}
