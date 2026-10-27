{...}: {
  flake.modules.homeManager.lazygit = {
    config,
    lib,
    pkgs,
    ...
  }: let
    configDir = "${config.xdg.configHome}/lazygit";
    themeFile = "${configDir}/theme.yml";
    pagerScript = pkgs.writeShellScriptBin "lazygit-pager" (builtins.readFile ../../dotfiles/scripts/lazygit-pager.sh);
  in {
    programs.lazygit.enable = true;

    home.packages = [pagerScript];

    home.sessionVariables.LG_CONFIG_FILE = "${configDir}/config.yml,${themeFile}";

    home.activation.lazygitTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "${themeFile}" ]; then
        mkdir -p "${configDir}"
        touch "${themeFile}"
      fi
    '';
  };
}
