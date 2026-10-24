{...}: {
  flake.modules.nixos-thinkpad.greetd = {...}: {
    systemd.services.greetd = {
      wants = ["fprintd.service"];
      after = ["fprintd.service"];
    };
  };
}
