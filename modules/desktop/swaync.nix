{...}: {
  flake.modules.homeManager.swaync = {lib, ...}: {
    services.swaync.enable = true;
    xdg.configFile."swaync/config.json".enable = lib.mkForce false;
  };
}
