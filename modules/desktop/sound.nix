{...}: {
  flake.modules.nixos.sound = {pkgs, ...}: {
    security.rtkit.enable = true;

    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
    ];

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      jack.enable = true;
      extraConfig.jack."10-low-latency" = {
        "jack.properties"."node.latency" = "256/48000";
      };
    };

    environment.systemPackages = with pkgs; [
      usbutils
      pciutils
      pipewire
      pipewire.jack
    ];
  };

  flake.modules.homeManager.sound = {
    inputs,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      ncmpcpp
      ncspot
      spotify-player
      spotify
      resonance
      easyeffects
      guitarix
      inputs.sonora.packages.${system}.sonora
    ];
  };
}
