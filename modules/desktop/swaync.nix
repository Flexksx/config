{...}: {
  flake.modules.homeManager.swaync = {...}: {
    services.swaync.enable = true;

    dotfiles.configFiles = [
      "swaync/config.json"
      "swaync/style.css"
    ];
  };
}
