{...}: {
  flake.modules.homeManager-thinkpad.sound = {pkgs, ...}: {
    home.file = {
      ".local/share/easyeffects/output/ThinkPad Unsuck.json".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/sebastian-de/easyeffects-thinkpad-unsuck/main/thinkpad-unsuck.json";
        sha256 = "0vfmc5rslza8nnk59hw25rff3pg1jbs7jb0ms36j2cp82zxvbbca";
      };
      ".local/share/easyeffects/output/Dolby Atmos.json".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Dolby%20Atmos.json";
        name = "dolby-atmos.json";
        sha256 = "1p8fxrrm2vrghk8w4vkrqrj984f8bj2bsqaa5c3k3lcx6i4iigz8";
      };
    };
  };
}
