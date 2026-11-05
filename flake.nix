{
  description = "Your new nix config";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    ponte.url = "github:flexksx/ponte";
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
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    pyprland.url = "github:hyprland-community/pyprland";
    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    zed.url = "github:zed-industries/zed";

    noctaliav5.url = "github:noctalia-dev/noctalia";
    mcmojave-hyprcursor.url = "github:libadoxon/mcmojave-hyprcursor";

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    voxtype = {
      url = "github:peteonrails/voxtype/v1.1.1-rc4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree [./modules]);
}
