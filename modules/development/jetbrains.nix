{...}: {
  flake.modules.homeManager.jetbrains = {pkgs, ...}: {
    home.packages = [pkgs.jetbrains-toolbox];
  };
}
