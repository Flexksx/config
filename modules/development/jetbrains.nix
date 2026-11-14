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
      home.packages = [unstable.jetbrains.idea];
      xdg.configFile."JetBrains/IntelliJIdea2026.2/idea64.vmoptions".text = ''
        -Xmx${config.jetbrains.maxHeap}
        ${builtins.readFile ../../dotfiles/jetbrains_ide/idea64.vmoptions}'';
    };
  };
}
