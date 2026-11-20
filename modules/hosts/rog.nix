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
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAQibXPJ9EU0W8NiQSIHFlzUw6hBQ86WTuZ09YD72UP pixel"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB0iAxnap5RQsqWG1QwECUOwROJHoXRlThTYOt5esnOF ipad"
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

          ollama = {
            enable = true;
            cuda = true;
          };

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
