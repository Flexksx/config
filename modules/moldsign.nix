{...}: {
  flake.modules.nixos.moldsign = {inputs, ...}: {
    imports = [inputs.moldsign.nixosModules.default];

    programs.moldsign.enable = true;
  };
}
