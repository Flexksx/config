{...}: {
  flake.modules.nixos.connectivity = {pkgs, ...}: {
    networking.networkmanager.enable = true;
    services.openssh.enable = true;

    users = {
      groups.autossh = {};
      users.autossh = {
        isSystemUser = true;
        group = "autossh";
      };
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Experimental = true;
        UserspaceHID = true;
      };
    };

    services.blueman.enable = true;

    networking.firewall = rec {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedTCPPorts = [57621];
      allowedUDPPortRanges = allowedTCPPortRanges;
      allowedUDPPorts = [5353];
    };

    programs.nm-applet.enable = true;

    environment.systemPackages = with pkgs; [
      networkmanagerapplet
      wireguard-tools
    ];
  };

  flake.modules.homeManager.connectivity = {pkgs, ...}: {
    home.packages = [pkgs.overskride];

    services.kdeconnect = {
      enable = true;
      package = pkgs.kdePackages.kdeconnect-kde;
      indicator = true;
    };
  };
}
