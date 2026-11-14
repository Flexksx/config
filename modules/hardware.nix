{...}: {
  flake.modules.nixos.hardware = {
    inputs,
    pkgs,
    lib,
    config,
    ...
  }: let
    plymouthThemeName = "hexagon_dots";
    pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      plymouth = {
        enable = true;
        theme = plymouthThemeName;
        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = [plymouthThemeName];
          })
        ];
      };
      kernelPackages = pkgs.linuxPackages_latest.extend (
        _: prev: {
          # Stable nixpkgs ships nvidia 595.71.05, whose open module calls strncpy
          # in kernel-open/nvidia/os-interface.c. Linux 7.3 removed strncpy, so the
          # stable driver does not compile against linuxPackages_latest. Take the
          # driver from unstable instead.
          inherit (pkgsUnstable.linuxPackagesFor prev.kernel) nvidiaPackages;
        }
      );
      extraModulePackages = with config.boot.kernelPackages; [ddcci-driver];
      kernelModules = ["ddcci-backlight"];
      initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };

    services.fwupd.enable = true;
    services.libinput.enable = true;

    # Noctalia reads battery state over the system bus from org.freedesktop.UPower.
    # Without the daemon there is no device object, so the battery widget renders nothing.
    services.upower.enable = true;

    hardware = {
      i2c.enable = true;
      enableAllFirmware = true;
    };

    networking.useDHCP = lib.mkDefault true;
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
