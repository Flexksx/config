{...}: {
  flake.modules.homeManager.zed = {
    pkgs,
    inputs,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  in {
    programs.zed-editor = {
      enable = true;
      package = unstable.zed-editor;
    };
  };
}
