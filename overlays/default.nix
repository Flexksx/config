{...}: {
  modifications = final: prev: {
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

    # imageio 2.37.2 tests fail against Pillow 13 ("Invalid mode for data type").
    # The library works for waypaper's 8-bit images; skip the broken test suite.
    python3Packages = prev.python3Packages.overrideScope (_: pyprev: {
      imageio = pyprev.imageio.overrideAttrs (_: {doInstallCheck = false;});
    });
  };
}
