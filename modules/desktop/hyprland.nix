{...}: let
  nix-cache = import ../_nix-cache.nix;
in {
  flake.modules.nixos.hyprland = {
    pkgs,
    inputs,
    ...
  }: {
    imports = [
      (nix-cache {
        url = "hyprland.cachix.org";
        key = "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=";
      })
      (nix-cache {
        url = "hyprland-community.cachix.org";
        key = "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSXnmE=";
      })
    ];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
      configPackages = with pkgs; [xdg-desktop-portal-gtk];
      config.common = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.Settings" = "gtk";
      };
    };

    programs.dconf = {
      enable = true;
      profiles.user.databases = [];
    };

    services.dbus = {
      enable = true;
      packages = with pkgs; [
        gtk3
        gsettings-desktop-schemas
      ];
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };

  flake.modules.homeManager.hyprland = {
    pkgs,
    inputs,
    ...
  }: {
    home.packages = with pkgs; [
      satty
      hyprshot
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      systemd.enable = false;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    xdg.configFile."hypr/hyprland.lua".source = "${inputs.self}/dotfiles/hypr/lua/init.lua";

    dotfiles.configFiles = ["hypr/.luarc.json"];

    home.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
      TERMINAL = "ghostty";
    };
  };
}
