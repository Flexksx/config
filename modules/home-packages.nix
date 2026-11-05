{...}: {
  flake.modules.homeManager.home-packages = {
    pkgs,
    inputs,
    lib,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "cursor"
            "code-cursor"
            "obsidian"
          ];
      };
    };

    musicPackages = with pkgs; [
      mpd
      mpc

      cava
      playerctl
    ];

    desktopPackages = with pkgs; [
      telegram-desktop
      slack
      discord
      scrcpy
      kdePackages.qttools

      gpu-screen-recorder-gtk
      gpu-screen-recorder

      google-chrome
      obsidian
      libreoffice-qt
      onlyoffice-desktopeditors
      postman
      dbeaver-bin
      fragments
      nautilus
      bitwarden-cli
      inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
      unstable.awww
      quickshell

      evince
      gnome-frog
      gnome-characters
      luminance
      waypaper
      unstable.nwg-displays
      pavucontrol
      icon-library
      libappindicator
      imv
      mpv
      mission-center
    ];

    systemSettingPackages = with pkgs; [
      upower
      ddcutil
      ddcui
      brightnessctl
      lm_sensors
      btop
      glib
      gsettings-desktop-schemas
      hunspell
    ];

    themingPackages = with pkgs; [
      material-symbols
      inputs.mcmojave-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  in {
    home.packages = musicPackages ++ desktopPackages ++ systemSettingPackages ++ themingPackages;

    programs = {
      zathura.enable = true;
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-pipewire-audio-capture
        ];
      };
    };

    targets.genericLinux.nixGL.vulkan.enable = true;
  };
}
