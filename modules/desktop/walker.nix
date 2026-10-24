{...}: {
  flake.modules.homeManager.walker = {
    inputs,
    pkgs,
    ...
  }: {
    imports = [inputs.walker.homeManagerModules.default];

    programs.walker = {
      enable = true;
      runAsService = true;
      config = {};
    };

    dotfiles.configFiles = ["walker/config.toml"];

    home.packages = [pkgs.imagemagick];
  };
}
