{...}: {
  flake.modules.nixos-rog.nvidia = {pkgs, ...}: {
    gpu.nvidia = {
      mode = "offload";
      busId = "PCI:1:0:0";
      igpu = {
        vendor = "amdgpu";
        busId = "PCI:6:0:0";
      };
    };

    boot.extraModprobeConfig = ''
      options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
    '';

    environment.systemPackages = [pkgs.supergfxctl];
    services.supergfxd.enable = true;

    environment.variables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      __GL_VRR_ALLOWED = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
