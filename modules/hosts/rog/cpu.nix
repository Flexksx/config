{...}: {
  flake.modules.nixos-rog.cpu = {pkgs, ...}: let
    powerProfilesMonitorScript = pkgs.writeShellApplication {
      name = "power-profile-monitor";
      runtimeInputs = with pkgs; [
        asusctl
        power-profiles-daemon
        dbus
        gnugrep
      ];
      text = builtins.readFile ../../../dotfiles/scripts/rog_powerprofilesctl_fan_curves.sh;
    };
  in {
    boot.kernelParams = ["amd_pstate=active"];

    services.power-profiles-daemon.enable = true;
    services.asusd = {
      enable = true;
    };
    services.tlp.enable = false;

    environment.systemPackages = with pkgs; [asusctl];

    # asus-shutdown ignores SIGTERM indefinitely during service restarts (upstream bug in 6.3.7)
    systemd.services.asus-shutdown.serviceConfig.SendSIGKILL = "yes";

    systemd.user.services.power-profile-monitor = {
      description = "Listen for power-profiles-daemon changes and update asusctl fan curves";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${powerProfilesMonitorScript}/bin/power-profile-monitor";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
