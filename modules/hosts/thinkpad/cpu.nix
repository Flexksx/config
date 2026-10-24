{...}: {
  flake.modules.nixos-thinkpad.cpu = {
    pkgs,
    lib,
    ...
  }: let
    thinkfanSensors = [
      {hwmon = "/run/sensors/thinkpad_temp1";}
      {hwmon = "/run/sensors/coretemp_temp1";}
      {hwmon = "/run/sensors/coretemp_temp2";}
      {hwmon = "/run/sensors/coretemp_temp3";}
      {hwmon = "/run/sensors/coretemp_temp4";}
      {hwmon = "/run/sensors/coretemp_temp5";}
    ];
    thinkfanFans = [{tpacpi = "/proc/acpi/ibm/fan";}];

    batteryLevels = [
      [0 0 45]
      [1 43 50]
      [3 47 55]
      [5 52 60]
      [7 57 65]
      ["level disengaged" 55 32767]
    ];
    # On AC: pin to the highest normal level, disengage once hot.
    acLevels = [
      [7 0 65]
      ["level disengaged" 60 32767]
    ];

    mkThinkfanConf = name: levels:
      (pkgs.formats.yaml {}).generate name {
        sensors = thinkfanSensors;
        fans = thinkfanFans;
        inherit levels;
      };
    batteryConf = mkThinkfanConf "thinkfan-battery.yaml" batteryLevels;
    acConf = mkThinkfanConf "thinkfan-ac.yaml" acLevels;
  in {
    services.power-profiles-daemon.enable = true;
    services.throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True

        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: 8
        PL1_Duration_s: 28
        PL2_Tdp_W: 12
        PL2_Duration_S: 0.002
        Trip_Temp_C: 70
        cTDP: 1
        Disable_BDPROCHOT: False

        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: 18
        PL1_Duration_s: 28
        PL2_Tdp_W: 28
        PL2_Duration_S: 0.002
        Trip_Temp_C: 75
        cTDP: 1
        Disable_BDPROCHOT: False

        [UNDERVOLT.BATTERY]
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0
      '';
    };

    boot.kernelParams = [
      "intel_pstate=active"
      "i915.enable_guc=3"
      "thinkpad_acpi.fan_control=1"
      "i915.enable_psr=1"
      "i915.enable_fbc=1"
      "i915.fastboot=1"
    ];
    boot.initrd.kernelModules = ["i915"];

    hardware = {
      cpu.intel.updateMicrocode = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          vulkan-tools
          intel-media-driver
          intel-vaapi-driver
          vpl-gpu-rt
          intel-compute-runtime
        ];
      };
    };

    systemd.services.thinkfan.preStart = ''
      mkdir -p /run/sensors
      found_coretemp=0
      found_thinkpad=0
      for d in /sys/class/hwmon/hwmon*; do
        name="$(cat $d/name 2>/dev/null)"
        if [ "$name" = "coretemp" ]; then
          for i in 1 2 3 4 5; do
            ln -sf "$d/temp''${i}_input" "/run/sensors/coretemp_temp''${i}"
          done
          found_coretemp=1
        fi
        if [ "$name" = "thinkpad" ]; then
          ln -sf "$d/temp1_input" "/run/sensors/thinkpad_temp1"
          found_thinkpad=1
        fi
      done
      [ "$found_coretemp" = "1" ] || { echo "coretemp hwmon not found" >&2; exit 1; }
      [ "$found_thinkpad" = "1" ] || { echo "thinkpad hwmon not found" >&2; exit 1; }

      if grep -qx 1 /sys/class/power_supply/AC*/online 2>/dev/null; then
        ln -sfn ${acConf} /run/thinkfan.conf
      else
        ln -sfn ${batteryConf} /run/thinkfan.conf
      fi
    '';

    # The upstream module bakes its own config path into THINKFAN_ARGS; point it
    # at the symlink chosen above instead.
    systemd.services.thinkfan.environment.THINKFAN_ARGS =
      lib.mkForce (lib.escapeShellArgs ["-c" "/run/thinkfan.conf"]);
    systemd.services.thinkfan.path = [pkgs.gnugrep];

    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="?*", RUN+="${pkgs.systemd}/bin/systemctl try-restart --no-block thinkfan.service"
    '';

    services.thinkfan = {
      enable = true;
      fans = [
        {
          type = "tpacpi";
          query = "/proc/acpi/ibm/fan";
        }
      ];
      levels = batteryLevels;
      settings.sensors = thinkfanSensors;
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
