{...}: {
  flake.modules.homeManager.theming = {
    pkgs,
    config,
    lib,
    ...
  }: let
    qtColors = "qt_matugen.conf";
    themeScriptPath = ../../dotfiles/scripts/themes/theme.sh;
  in {
    # GTK
    gtk = {
      enable = true;
      theme = {
        package = pkgs.adw-gtk3;
        name = "adw-gtk3";
      };
      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus";
      };
      gtk3 = {
        extraCss = ''
          @import url("matugen.css");
        '';
        theme = config.gtk.theme;
      };
      gtk4 = {
        extraCss = ''
          @import url("matugen.css");
        '';
        theme = config.gtk.theme;
      };
    };

    # Qt
    qt = {
      enable = true;
      platformTheme.name = "xdgdesktopportal";
      style.name = "kvantum";
    };

    xdg.configFile."qt5ct/qt5ct.conf".text = lib.generators.toINI {} {
      Appearance = {
        icon_theme = "Papirus-Dark";
        custom_palette = true;
        color_scheme_path = "${config.home.homeDirectory}/.config/qt5ct/colors/${qtColors}";
      };
    };

    xdg.configFile."qt6ct/qt6ct.conf".text = lib.generators.toINI {} {
      Appearance = {
        icon_theme = "Papirus-Dark";
        custom_palette = true;
        color_scheme_path = "${config.home.homeDirectory}/.config/qt6ct/colors/${qtColors}";
      };
    };

    # Dark/light mode
    services.darkman = {
      enable = true;
      settings = {
        lat = 47.0;
        lng = 28.8;
      };
      darkModeScripts.gtk-theme = ''
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3-dark'"
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme "'Papirus-Dark'"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
      '';
      lightModeScripts.gtk-theme = ''
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'adw-gtk3'"
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme "'Papirus'"
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-light
      '';
    };

    systemd.user.startServices = "sd-switch";

    home.packages = with pkgs; [
      # GTK tooling
      glib
      nwg-look
      dconf
      gsettings-desktop-schemas
      # Qt tooling
      libsForQt5.qt5ct
      kdePackages.qt6ct
      kdePackages.qtstyleplugin-kvantum
      kdePackages.qtdeclarative
      kdePackages.qtbase
      qt6.qtimageformats
      qt6.qtsvg
      # Darkman portal
      xdg-desktop-portal-gtk
      # Color scheme generator
      matugen
      # Theme switcher script
      (pkgs.writeShellScriptBin "theme" (builtins.readFile themeScriptPath))
    ];
  };
}
