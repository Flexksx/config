{...}: {
  flake.modules.nixos-rog.nvidia = {
    gpu.nvidia = {
      mode = "offload";
      busId = "PCI:1:0:0";
      igpu = {
        vendor = "amdgpu";
        busId = "PCI:6:0:0";
      };
    };

    environment.variables = {
      __GL_VRR_ALLOWED = "1";
      AQ_DRM_DEVICES = "/dev/dri/igpu";
    };
  };
}
