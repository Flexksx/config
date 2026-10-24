{...}: {
  flake.modules.homeManager.desktop-idle = {pkgs, ...}: let
    dimTimeout = 150;
    kbdOffTimeout = 250;
    screenOffTimeout = 600;
    lockTimeout = 900;
    suspendTimeout = 1800;
  in {
    services.hyprsunset.enable = true;

    services.hypridle = {
      enable = true;
      package = pkgs.hypridle;
      settings = {
        general = {
          lock_cmd = "noctalia-shell ipc call lockScreen lock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = dimTimeout;
            on-timeout = "brightnessctl -s set 10";
            on-resume = "brightnessctl -r";
          }
          {
            timeout = kbdOffTimeout;
            on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
            on-resume = "brightnessctl -rd rgb:kbd_backlight";
          }
          {
            timeout = screenOffTimeout;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = lockTimeout;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = suspendTimeout;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
