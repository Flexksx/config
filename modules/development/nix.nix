{...}: {
  flake.modules.nixos.nix-ld = {...}: {
    programs.nix-ld.enable = true;
  };

  flake.modules.homeManager.nix-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      nixfmt-tree
      nixfmt
      nixd
      hyprls
    ];
  };
}
