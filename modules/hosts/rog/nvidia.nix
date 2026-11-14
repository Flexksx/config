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

    environment.systemPackages = [pkgs.supergfxctl];
    services.supergfxd.enable = true;

    hardware.nvidia.dynamicBoost.enable = true;

    environment.variables = {
      __GL_VRR_ALLOWED = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
