{...}: {
  flake.modules.nixos.zram = {...}: {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    boot.kernel.sysctl."vm.swappiness" = 10;
  };
}
