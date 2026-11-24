{...}: let
  nix-cache = import ../_nix-cache.nix;
in {
  flake.modules.nixos.yazi-cache = nix-cache {
    url = "yazi.cachix.org";
    key = "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=";
  };

  flake.modules.homeManager.yazi = {
    pkgs,
    inputs,
    ...
  }: {
    programs.yazi = {
      enable = true;
      package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;
      shellWrapperName = "y";
    };

    home.packages = [
      pkgs.glow
    ];

    dotfiles.configFiles = [
      "yazi/yazi.toml"
      "yazi/init.lua"
    ];
  };
}
