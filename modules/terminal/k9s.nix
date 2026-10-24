{...}: {
  flake.modules.homeManager.k9s = {pkgs, ...}: {
    home.packages = [
      pkgs.k9s
      pkgs.kubectl
      pkgs.lnav
      pkgs.jq
    ];

    dotfiles.configFiles = [
      "k9s/config.yaml"
      "k9s/plugins.yaml"
    ];
  };
}
