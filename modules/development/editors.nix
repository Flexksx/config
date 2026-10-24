{...}: {
  flake.modules.homeManager.editors = {pkgs, ...}: {
    programs.vscode = {
      enable = true;
      # X11 keeps subpixel font smoothing, which Chromium turns off on Wayland.
      package = pkgs.vscode.override {commandLineArgs = "--ozone-platform=x11";};
    };
  };
}
