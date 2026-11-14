{...}: let
  nix-cache = import ../_nix-cache.nix;
in {
  flake.modules.nixos.zed-cache = nix-cache {
    url = "zed.cachix.org";
    key = "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU=";
  };

  flake.modules.homeManager.zed = {
    pkgs,
    inputs,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  in {
    programs.zed-editor = {
      enable = true;
      package = unstable.zed-editor;
    };
  };
}
