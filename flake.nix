{
  description = "Your new nix config";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    claude-code.url = "github:sadjow/claude-code-nix";
    opencode.url = "github:anomalyco/opencode/v2.1.2";
    turb = {
      url = "github:flexksx/turb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sonora.url = "github:sonorahq/sonora";
    slackcli.url = "github:Flexksx/slackcli";
    moldsign = {
      url = "github:Flexksx/moldsign";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    yazi.url = "github:sxyazi/yazi";

    hyprland.url = "github:hyprwm/Hyprland/v0.56.1";

    noctaliav5.url = "github:noctalia-dev/noctalia";
    mcmojave-hyprcursor.url = "github:libadoxon/mcmojave-hyprcursor";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree [./modules]);
}
