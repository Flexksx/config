{...}: {
  flake.modules.nixos.virtualisation = {...}: {
    virtualisation.docker.enable = true;
    virtualisation.libvirtd.enable = true;
  };
}
