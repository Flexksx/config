{...}: {
  flake.modules.homeManager.editors = {unstable, ...}: {
    programs.vscode = {
      enable = true;
      # X11 keeps subpixel font smoothing, which Chromium turns off on Wayland.
      package = unstable.vscode.override {commandLineArgs = "--ozone-platform=x11";};
    };
  };
}
