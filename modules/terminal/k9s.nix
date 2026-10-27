{...}: {
  flake.modules.homeManager.k9s = {pkgs, ...}: {
    home.packages = [
      pkgs.k9s
      pkgs.kubectl
      pkgs.lnav
      pkgs.jq
    ];
  };
}
