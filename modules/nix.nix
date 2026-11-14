{inputs, ...}: {
  systems = [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  flake.overlays = import ../overlays {};

  flake.modules.nixos.nix = {
    lib,
    config,
    ...
  }: let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        flake-registry = "";
        nix-path = config.nix.nixPath;
        max-jobs = "auto";
        cores = 0;
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
  };

  flake.modules.nixos.nixpkgs = {outputs, ...}: {
    nixpkgs = {
      overlays = [outputs.overlays.modifications];
      config.allowUnfree = true;
    };
  };

  flake.modules.homeManager.nixpkgs = {outputs, ...}: {
    nixpkgs = {
      overlays = [outputs.overlays.modifications];
      config = {
        allowUnfree = true;
        permittedInsecurePackages = ["electron-39.8.10"];
      };
    };
  };
}
