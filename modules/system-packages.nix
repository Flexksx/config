{...}: {
  flake.modules.nixos.system-packages = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      home-manager
      gnupg
      gedit
      lsof
      polkit
      firefox
      polkit_gnome
      git-credential-manager
      gnome-disk-utility
      openjdk17
      platformio
      udiskie
      git
      gnumake
      avrdude
      killall
      cheese
      wlr-randr
      pass
      clang
      cmake
      gsettings-desktop-schemas
      parted
      ouch
      jq
      jaq
      libnotify
      glib
      pinentry-gnome3
      starship
      fprintd
      pciutils
      ffmpeg
      bat
      pkg-config
      file-roller
      meson
      hyprpicker
      ninja
      brightnessctl
      imv
      mpv
      wallust
      lm_sensors
      wlrctl
      jira-cli-go
      acli
    ];

    programs.zsh.enable = true;

    services.printing.enable = true;
    services.tumbler.enable = true;

    users.defaultUserShell = pkgs.zsh;
    security.polkit.enable = true;
    security.sudo.wheelNeedsPassword = false;
  };
}
