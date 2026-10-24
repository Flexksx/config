{...}: {
  flake.modules.nixos.nix-settings = {...}: {
    nix.extraOptions = ''
      !include /etc/nix/access-tokens.conf
    '';
  };

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
