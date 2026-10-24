{...}: {
  flake.modules.nixos.fonts = {
    pkgs,
    inputs,
    ...
  }: {
    fonts = {
      enableDefaultPackages = true;

      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.droid-sans-mono
        fira
        noto-fonts-color-emoji
        meslo-lgs-nf
        font-awesome
        material-icons
        material-symbols
        google-fonts
        liberation_ttf
        source-serif-pro
        inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro
        inter
        ibm-plex
        lilex
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          style = "slight";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "light";
        };
        defaultFonts = {
          sansSerif = ["IBM Plex Sans" "SF Pro Display" "SF Pro Text" "Noto Sans"];
          monospace = ["JetBrains Mono" "SF Mono" "IBM Plex Mono"];
          emoji = ["Noto Color Emoji"];
        };
      };
    };
  };
}
