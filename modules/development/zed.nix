{...}: {
  flake.modules.homeManager.zed = {
    pkgs,
    inputs,
    ...
  }: {
    programs.zed-editor = {
      enable = true;
      package = inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
