{...}: {
  flake.modules.homeManager.noctalia = {
    inputs,
    lib,
    ...
  }: {
    imports = [inputs.noctaliav5.homeModules.default];

    programs.noctalia.enable = true;

    dotfiles.configFiles = ["noctalia/config.toml"];

    xdg.configFile."noctalia/user-templates.toml" = lib.mkForce {text = "";};
  };
}
