{...}: {
  flake.modules.homeManager.dotfiles = {
    config,
    lib,
    ...
  }: let
    root = "${config.home.homeDirectory}/config/dotfiles";
    link = relativePath: config.lib.file.mkOutOfStoreSymlink "${root}/${relativePath}";
    entry = lib.types.either lib.types.str (lib.types.attrsOf lib.types.str);
    symlink = source:
      lib.mkForce {
        source = link source;
        force = true;
      };
    toEntry = item:
      if builtins.isString item
      then lib.nameValuePair item (symlink item)
      else lib.nameValuePair item.target (symlink item.source);
    toFiles = items: builtins.listToAttrs (map toEntry items);
  in {
    options.dotfiles = {
      configFiles = lib.mkOption {
        type = lib.types.listOf entry;
        default = [];
        description = ''
          Dotfiles to symlink into the XDG config directory. A string uses the
          same path under dotfiles/ and under the config directory. An attribute
          set of target and source sets the two paths apart.
        '';
      };

      homeFiles = lib.mkOption {
        type = lib.types.listOf entry;
        default = [];
        description = ''
          Dotfiles to symlink into the home directory. The entries have the same
          shape as the entries of dotfiles.configFiles.
        '';
      };
    };

    config = {
      lib.dotfiles = {
        inherit root link;
        path = relativePath: "${root}/${relativePath}";
      };

      xdg.configFile = toFiles config.dotfiles.configFiles;
      home.file = toFiles config.dotfiles.homeFiles;
    };
  };
}
