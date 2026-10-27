{...}: {
  flake.modules.homeManager.zed = {pkgs, ...}: {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
    };
  };
}
