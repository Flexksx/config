{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      outputs = config.flake;
    };
    modules =
      (builtins.attrValues config.flake.modules.nixos)
      ++ (builtins.attrValues config.flake.modules.nixos-rog)
      ++ [config.flake.modules.nixos-optional.nvidia]
      ++ [
        ({pkgs, ...}: {
          environment.systemPackages = with pkgs; [
            pipewire
            mixxx
            qpwgraph
          ];

          nix.settings.trusted-users = [
            "root"
            "@wheel"
          ];

          networking.hostName = "nixos";

          rgb.motherboard = "amd";

          programs.steam.enable = true;

          security.polkit.extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (
                subject.isInGroup("users")
                  && (
                    action.id == "org.freedesktop.login1.reboot" ||
                    action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                    action.id == "org.freedesktop.login1.power-off" ||
                    action.id == "org.freedesktop.login1.power-off-multiple-sessions"
                  )
                )
              {
                return polkit.Result.YES;
              }
            })
          '';

          users = {
            groups.flexksx = {};
            users.flexksx = {
              isNormalUser = true;
              group = "flexksx";
              extraGroups = [
                "wheel"
                "audio"
                "kvm"
                "libvirtd"
                "video"
                "networkmanager"
                "systemd-journal"
                "systemd-network"
                "plugdev"
                "render"
                "docker"
                "dialout"
                "openrazer"
                "i2c"
              ];
            };
          };

          system.stateVersion = "24.11";
        })
      ];
  };

  flake.homeConfigurations."flexksx@nixos" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = {
      inherit inputs;
      outputs = config.flake;
    };
    modules =
      (builtins.attrValues config.flake.modules.homeManager)
      ++ [
        {
          home = {
            username = "flexksx";
            homeDirectory = "/home/flexksx";
            stateVersion = "24.11";
          };
          programs.home-manager.enable = true;
          programs.git-config.email = "cristian.cretu2808@gmail.com";

          services.drivesync.mounts.gdrive = {
            enable = true;
            path = "%h/GoogleDrive";
          };

          services.drivesync.syncs.wallpapers = {
            enable = true;
            mode = "copy";
            source = "%h/config/backgrounds";
            destination = "backgrounds";
          };
        }
      ];
  };
}
