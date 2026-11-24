{...}: let
  nix-cache = import ../_nix-cache.nix;
in {
  flake.modules.nixos.noctalia-cache = nix-cache {
    url = "noctalia.cachix.org";
    key = "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=";
  };

  flake.modules.homeManager.noctalia = {
    inputs,
    lib,
    ...
  }: {
    imports = [inputs.noctaliav5.homeModules.default];

    programs.noctalia.enable = true;

    xdg.configFile."noctalia/user-templates.toml" = lib.mkForce {text = "";};
  };
}
