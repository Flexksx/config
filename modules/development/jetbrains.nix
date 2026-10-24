{...}: {
  flake.modules.homeManager.jetbrains = {
    config,
    lib,
    unstable,
    ...
  }: {
    options.jetbrains.maxHeap = lib.mkOption {
      type = lib.types.str;
      default = "8g";
      description = "Maximum JVM heap size for IntelliJ IDEA.";
    };

    config = {
      home.packages = [
        (unstable.jetbrains.idea.overrideAttrs (_: rec {
          version = "2026.2.3";
          src = unstable.fetchurl {
            url = "https://download.jetbrains.com/idea/ideaIU-${version}.tar.gz";
            hash = "sha256-aHUciuTUlAclHNGX33lfvtkbb9yF0QxzxGSameSWqzc=";
          };
        }))
      ];
      xdg.configFile."JetBrains/IntelliJIdea2026.2/idea64.vmoptions".text = ''
        -Xmx${config.jetbrains.maxHeap}
        ${builtins.readFile ../../dotfiles/jetbrains_ide/idea64.vmoptions}'';
      dotfiles.homeFiles = [
        {
          target = ".ideavimrc";
          source = "jetbrains_ide/.ideavimrc";
        }
      ];
      dotfiles.configFiles = [
        {
          target = "JetBrains/IntelliJIdea2026.2/keymaps/Shared.xml";
          source = "jetbrains_ide/keymaps/Shared.xml";
        }
        {
          target = "JetBrains/IntelliJIdea2026.2/options/keymap.xml";
          source = "jetbrains_ide/options/keymap.xml";
        }
      ];
    };
  };
}
