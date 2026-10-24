{...}: {
  flake.modules.homeManager.dev-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      cmake
      meson
      cpio
    ];
  };
}
