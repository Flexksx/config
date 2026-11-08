{...}: {
  flake.modules.homeManager.nix-github-token = {
    config,
    pkgs,
    ...
  }: {
    nix.extraOptions = ''
      !include ${config.xdg.stateHome}/nix/access-tokens.conf
    '';

    nix.package = pkgs.nix;

    systemd.user.services.nix-github-token = {
      Unit = {
        Description = "Write the GitHub token that nix uses to fetch flake inputs";
        Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellApplication {
          name = "nix-github-token";
          runtimeInputs = [pkgs.gh pkgs.coreutils];
          text = ''
            out="$HOME/.local/state/nix/access-tokens.conf"
            install -d -m 700 "$(dirname "$out")"
            umask 077
            for _ in 1 2 3 4 5; do
              if token="$(gh auth token --hostname github.com 2>/dev/null)"; then
                printf 'access-tokens = github.com=%s\n' "$token" > "$out"
                exit 0
              fi
              sleep 3
            done
            echo "nix-github-token: gh returned no token after 5 attempts" >&2
            exit 1
          '';
        }}/bin/nix-github-token";
      };
      Install.WantedBy = ["default.target"];
    };

    systemd.user.timers.nix-github-token = {
      Unit.Description = "Refresh the nix GitHub token";
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
        Unit = "nix-github-token.service";
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
