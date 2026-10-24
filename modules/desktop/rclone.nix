{...}: {
  flake.modules.homeManager.rclone = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.drivesync;

    networkUnit = {
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    mkMountService = name: mountCfg: {
      Unit =
        {
          Description = "Rclone mount ${name}";
        }
        // networkUnit;
      Service = {
        Type = "notify";
        ExecStartPre = [
          "-${pkgs.fuse}/bin/fusermount -u -z ${mountCfg.path}"
          "${pkgs.coreutils}/bin/mkdir -p ${mountCfg.path}"
        ];
        ExecStart = lib.concatStringsSep " " (
          [
            "${pkgs.rclone}/bin/rclone"
            "mount"
            "${mountCfg.drive}:"
            mountCfg.path
          ]
          ++ mountCfg.extraArgs
        );
        ExecStop = "${pkgs.fuse}/bin/fusermount -u -z ${mountCfg.path}";
        Restart = mountCfg.restart;
        RestartSec = mountCfg.restartSec;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    mkSyncService = name: syncCfg: {
      Unit =
        {
          Description = "Rclone sync ${name}";
        }
        // networkUnit;
      Service = {
        Type = "oneshot";
        ExecStart = lib.concatStringsSep " " (
          [
            "${pkgs.rclone}/bin/rclone"
            "sync"
            syncCfg.source
            "${syncCfg.drive}:${syncCfg.destination}"
            "--log-file"
            "%h/.cache/rclone-sync-${name}.log"
          ]
          ++ syncCfg.extraArgs
        );
      };
    };

    mkSyncTimer = name: syncCfg: {
      Unit = {
        Description = "Rclone sync ${name} timer";
      };
      Timer = {
        OnCalendar = syncCfg.timer;
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  in {
    options.services.drivesync = {
      mounts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {...}: {
              options = {
                enable = lib.mkEnableOption "rclone mount";
                drive = lib.mkOption {
                  type = lib.types.str;
                  default = "personal-google-drive";
                  description = "Rclone remote name";
                };
                path = lib.mkOption {
                  type = lib.types.str;
                  description = "Local mount path";
                };
                extraArgs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    "--vfs-cache-mode"
                    "full"
                    "--vfs-cache-max-age"
                    "24h"
                    "--vfs-read-chunk-size"
                    "128M"
                    "--dir-cache-time"
                    "72h"
                  ];
                  description = "Extra arguments passed to rclone mount";
                };
                restart = lib.mkOption {
                  type = lib.types.str;
                  default = "on-failure";
                  description = "Systemd Restart policy";
                };
                restartSec = lib.mkOption {
                  type = lib.types.str;
                  default = "10s";
                  description = "Systemd RestartSec interval";
                };
              };
            }
          )
        );
        default = {};
        description = "Rclone mount definitions";
      };

      syncs = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {...}: {
              options = {
                enable = lib.mkEnableOption "rclone sync";
                drive = lib.mkOption {
                  type = lib.types.str;
                  default = "personal-google-drive";
                  description = "Rclone remote name";
                };
                source = lib.mkOption {
                  type = lib.types.str;
                  description = "Local source path";
                };
                destination = lib.mkOption {
                  type = lib.types.str;
                  description = "Remote destination (appended to drive:)";
                };
                timer = lib.mkOption {
                  type = lib.types.str;
                  default = "daily";
                  description = "Systemd OnCalendar schedule";
                };
                extraArgs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [];
                  description = "Extra arguments passed to rclone sync";
                };
              };
            }
          )
        );
        default = {};
        description = "Rclone sync definitions";
      };
    };

    config = lib.mkMerge [
      {
        home.packages = with pkgs; [
          rclone
          rclone-browser
        ];
      }

      (lib.mkIf (cfg.mounts != {}) {
        systemd.user.services = lib.mapAttrs' (
          name: mountCfg: lib.nameValuePair "rclone-mount-${name}" (mkMountService name mountCfg)
        ) (lib.filterAttrs (_: m: m.enable) cfg.mounts);
      })

      (lib.mkIf (cfg.syncs != {}) {
        systemd.user.services = lib.mapAttrs' (
          name: syncCfg: lib.nameValuePair "rclone-sync-${name}" (mkSyncService name syncCfg)
        ) (lib.filterAttrs (_: s: s.enable) cfg.syncs);

        systemd.user.timers = lib.mapAttrs' (
          name: syncCfg: lib.nameValuePair "rclone-sync-${name}" (mkSyncTimer name syncCfg)
        ) (lib.filterAttrs (_: s: s.enable) cfg.syncs);
      })
    ];
  };
}
