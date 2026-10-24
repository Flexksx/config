{...}: {
  flake.modules.nixos.gnome-settings = {pkgs, ...}: {
    services.gnome = {
      gnome-keyring.enable = true;
      gcr-ssh-agent.enable = true;
      gnome-online-accounts.enable = true;
      evolution-data-server.enable = true;
    };
    services.accounts-daemon.enable = true;
    services.gvfs = {
      enable = true;
      package = pkgs.gnome.gvfs;
    };
    security.pam.services.greetd.enableGnomeKeyring = true;
    security.pam.services.login.enableGnomeKeyring = true;
  };

  flake.modules.homeManager.gnome-settings = {pkgs, ...}: {
    home.packages = with pkgs; [
      nautilus
      gnome-control-center
      gnome-calculator
      gnome-system-monitor
      gnome-calendar
      seahorse
      libsecret
    ];

    programs.zsh.shellAliases = {
      gnome-accounts = "dbus-run-session -- env XDG_CURRENT_DESKTOP=GNOME gnome-control-center online-accounts";
    };
  };
}
