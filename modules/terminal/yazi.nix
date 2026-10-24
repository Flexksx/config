{...}: {
  flake.modules.homeManager.yazi = {
    config,
    pkgs,
    ...
  }: let
    localPlugin = name: config.lib.dotfiles.link "yazi/plugins/${name}.yazi";
  in {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";

      plugins = {
        git-worktrees = localPlugin "git-worktrees";
        duckdb = pkgs.yaziPlugins.duckdb;
        glow = pkgs.yaziPlugins.glow;
        git = pkgs.yaziPlugins.git;
        githead = pkgs.yaziPlugins.githead;
      };
    };

    home.packages = [
      pkgs.duckdb
      pkgs.glow
    ];

    dotfiles.configFiles = [
      "yazi/yazi.toml"
      "yazi/init.lua"
      "yazi/keymap.toml"
    ];
  };
}
