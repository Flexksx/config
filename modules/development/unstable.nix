{inputs, ...}: {
  flake.modules.homeManager.unstable = {
    pkgs,
    lib,
    ...
  }: {
    _module.args.unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "idea-ultimate"
          ];
      };
    };
  };
}
