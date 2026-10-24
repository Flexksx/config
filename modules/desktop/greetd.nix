{...}: {
  flake.modules.nixos.greetd = {
    pkgs,
    config,
    ...
  }: let
    uwsmSessions = pkgs.runCommand "uwsm-sessions" {} ''
      mkdir -p $out
      for f in ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions/*-uwsm.desktop; do
        ln -s "$f" $out/
      done
    '';
  in {
    boot.kernelParams = ["quiet"];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.tuigreet}/bin/tuigreet \
              --time \
              --remember \
              --remember-session \
              --asterisks \
              --sessions ${uwsmSessions}
          '';
          user = "greeter";
        };
      };
    };

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };
}
