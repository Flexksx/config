{...}: {
  flake.modules.nixos-optional.nvidia = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.gpu.nvidia;
    hex = s: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString (lib.toIntBase10 s)));
    sysfsAddress = busId: let
      parts = lib.splitString ":" busId;
    in "0000:${hex (builtins.elemAt parts 1)}:${hex (builtins.elemAt parts 2)}.${builtins.elemAt parts 3}";
    nvidiaPrimaryEnv = {
      LIBVA_DRIVER_NAME = lib.mkForce "nvidia";
      NVD_BACKEND = "direct";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  in {
    options.gpu.nvidia = {
      mode = lib.mkOption {
        type = lib.types.enum ["offload" "sync"];
        description = "PRIME mode. Offload renders on the iGPU, sync renders on the NVIDIA GPU.";
      };
      busId = lib.mkOption {
        type = lib.types.str;
        description = "Bus ID of the NVIDIA GPU, for example PCI:1:0:0.";
      };
      igpu = {
        vendor = lib.mkOption {
          type = lib.types.enum ["intel" "amdgpu"];
          description = "Vendor of the integrated GPU.";
        };
        busId = lib.mkOption {
          type = lib.types.str;
          description = "Bus ID of the integrated GPU, for example PCI:0:2:0.";
        };
      };
      desktopSpecialisation = lib.mkEnableOption "a boot entry that renders the whole desktop on the NVIDIA GPU";
    };

    config = lib.mkMerge [
      {
        services.xserver.videoDrivers = lib.optional (cfg.igpu.vendor == "amdgpu") "amdgpu" ++ ["nvidia"];

        boot.kernelParams = ["nvidia_drm.modeset=1"];

        services.udev.extraRules = ''
          SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="${sysfsAddress cfg.igpu.busId}", SYMLINK+="dri/igpu"
          SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="${sysfsAddress cfg.busId}", SYMLINK+="dri/dgpu"
        '';

        hardware = {
          graphics = {
            enable = true;
            extraPackages = [pkgs.nvidia-vaapi-driver];
          };

          nvidia = {
            modesetting.enable = true;
            open = true;
            nvidiaSettings = true;
            powerManagement = {
              enable = false;
              finegrained = false;
            };
            prime = {
              "${cfg.igpu.vendor}BusId" = lib.mkForce cfg.igpu.busId;
              nvidiaBusId = cfg.busId;
              sync.enable = cfg.mode == "sync";
              offload = lib.mkIf (cfg.mode == "offload") {
                enable = true;
                enableOffloadCmd = true;
              };
            };
            package = config.boot.kernelPackages.nvidiaPackages.production;
          };
        };
      }

      (lib.mkIf (cfg.mode == "sync") {
        environment.sessionVariables = nvidiaPrimaryEnv;
      })

      (lib.mkIf cfg.desktopSpecialisation {
        specialisation.nvidia.configuration = {
          system.nixos.tags = ["nvidia"];
          hardware.nvidia.powerManagement.finegrained = lib.mkForce false;
          environment.sessionVariables =
            nvidiaPrimaryEnv
            // {
              AQ_DRM_DEVICES = "/dev/dri/dgpu:/dev/dri/igpu";
            };
        };
      })
    ];
  };
}
