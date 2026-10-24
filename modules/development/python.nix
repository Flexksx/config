{...}: {
  flake.modules.homeManager.python-dev = {pkgs, ...}: {
    home.packages = with pkgs; [jinja-lsp python314 uv];
  };
}
