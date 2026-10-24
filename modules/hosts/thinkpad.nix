{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations.ccretu-nixos = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      outputs = config.flake;
    };
    modules =
      (builtins.attrValues config.flake.modules.nixos)
      ++ (builtins.attrValues config.flake.modules.nixos-thinkpad)
      ++ [
        ({pkgs, ...}: {
          nix.settings.trusted-users = [
            "root"
            "ccretu"
          ];

          boot.loader.systemd-boot.configurationLimit = 30;

          networking.hostName = "ccretu-nixos";

          rgb.motherboard = "intel";

          services = {
            xserver = {
              enable = true;
              xkb.layout = "us";
              videoDrivers = ["modesetting"];
            };
            devmon.enable = true;
            udisks2.enable = true;
            hardware.bolt.enable = true;
          };

          virtualisation.libvirtd.enable = true;

          programs = {
            thunar.enable = true;
            nix-ld.libraries = with pkgs; [
              brotli
              glib
            ];
          };

          system.autoUpgrade.enable = true;

          services.udev.packages = [pkgs.platformio];
          environment.systemPackages = [pkgs.awscli];

          users = {
            groups.ccretu = {};
            users.ccretu = {
              isNormalUser = true;
              group = "ccretu";
              extraGroups = [
                "wheel"
                "audio"
                "kvm"
                "libvirtd"
                "video"
                "systemd-journal"
                "systemd-network"
                "plugdev"
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

  flake.homeConfigurations."ccretu@ccretu-nixos" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = {
      inherit inputs;
      outputs = config.flake;
    };
    modules =
      (builtins.attrValues config.flake.modules.homeManager)
      ++ (builtins.attrValues config.flake.modules.homeManager-thinkpad)
      ++ [
        ({lib, ...}: {
          home = {
            username = "ccretu";
            homeDirectory = "/home/ccretu";
            stateVersion = "24.11";
          };
          programs.home-manager.enable = true;
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings = {
              "github.com" = lib.hm.dag.entryAfter ["*"] {
                HostName = "github.com";
                User = "git";
                IdentityFile = ["~/.ssh/id_ed25519"];
                IdentitiesOnly = true;
              };
            };
          };
        })
      ];
  };
}
