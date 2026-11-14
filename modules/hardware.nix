{...}: {
  flake.modules.nixos.hardware = {
    pkgs,
    lib,
    config,
    ...
  }: let
    plymouthThemeName = "hexagon_dots";
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
          ddcci-driver = prev.ddcci-driver.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                sed -i 's/strncpy(buf, device->\([a-z]*\), PAGE_SIZE);/memcpy(buf, device->\1, len);/' ddcci/ddcci.c
                ! grep -q strncpy ddcci/ddcci.c
              '';
          });
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
