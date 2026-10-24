{...}: {
  flake.modules.nixos.rgb = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.rgb.motherboard = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["amd" "intel"]);
      default = null;
      description = "Motherboard platform for OpenRGB hardware detection. Null disables OpenRGB.";
    };

    config = lib.mkMerge [
      {
        hardware.openrazer.enable = true;

        environment.systemPackages = with pkgs; [
          openrazer-daemon
          polychromatic
        ];
      }
      (lib.mkIf (config.rgb.motherboard != null) {
        services.hardware.openrgb = {
          package = pkgs.openrgb-with-all-plugins;
          enable = true;
          motherboard = config.rgb.motherboard;
        };

        services.udev.packages = [
          (pkgs.runCommand "openrgb-udev-rules" {} ''
            mkdir -p $out/lib/udev/rules.d
            substitute ${./openrgb/60-openrgb.rules} $out/lib/udev/rules.d/60-openrgb.rules \
              --replace-warn /usr/bin/env ${pkgs.coreutils}/bin/env
          '')
        ];
      })
    ];
  };
}
