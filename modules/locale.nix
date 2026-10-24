{...}: {
  flake.modules.nixos.locale = {...}: {
    time.timeZone = "Europe/Chisinau";
    i18n.defaultLocale = "en_US.UTF-8";
  };
}
