{inputs, ...}: {
  additions = final: prev: import ../pkgs {pkgs = prev;};

  modifications = final: prev: {
    openblas =
      if prev.stdenv.hostPlatform.is32bit
      then prev.openblas.overrideAttrs (_: {doCheck = false;})
      else prev.openblas;

    guitarix = prev.guitarix.overrideAttrs (old: {
      patches =
        old.patches
        ++ [
          (final.fetchpatch2 {
            name = "fix-online-preset-download.patch";
            url = "https://github.com/brummer10/guitarix/compare/v0.47.0..987f58e4e36dfcc639b23823bb04a56546f93690.patch?full_index=1";
            hash = "sha256-Mfscwci2kvZ6VLUB0E6QUxdd7qqjJdiCuvl0NZgAMkM=";
            includes = [
              "trunk/src/gx_head/gui/gx_preset_window.cpp"
              "trunk/src/headers/gx_preset_window.h"
            ];
          })
        ];
    });
  };

  # Define the overlay to include openrazer-daemon directly from unstable
  unstable-packages = final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
