{...}: {
  flake.modules.homeManager.rclone = {
    inputs,
    lib,
    pkgs,
    ...
  }: {
    systemd.user.services.rclone-google-drive = {
      Unit = {
        Description = "Rclone Google Drive Mount";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        Type = "notify";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount personal-google-drive: %h/GoogleDrive \
            --vfs-cache-mode full \
            --vfs-cache-max-age 24h \
            --vfs-read-chunk-size 128M \
            --dir-cache-time 72h
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -u %h/GoogleDrive";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
