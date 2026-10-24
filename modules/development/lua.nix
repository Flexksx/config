{...}: {
  flake.modules.homeManager.lua-dev = {pkgs, ...}: {
    home.packages = with pkgs; [
      stylua
      lua-language-server
    ];
  };
}
