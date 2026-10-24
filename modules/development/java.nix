{...}: {
  flake.modules.homeManager.java = {
    pkgs,
    lib,
    ...
  }: let
    springBootExt = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "vmware";
        name = "vscode-spring-boot";
        version = "2.2.2026043000";
        sha256 = "1cvjjpn6x99psl0031maxv888x8mx8vd4nh3hs8l4m9zqc2bz6h8";
      };
    };
  in {
    options.programs.development.springBootLspJar = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "${springBootExt}/share/vscode/extensions/vmware.vscode-spring-boot/language-server/spring-boot-language-server-2.2.0-SNAPSHOT-exec.jar";
      description = "Path to the Spring Boot language server JAR.";
    };

    config.programs.vscode.profiles.default.extensions = [springBootExt];
  };
}
