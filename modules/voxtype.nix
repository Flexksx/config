{inputs, ...}: {
  flake.modules.homeManager-optional.voxtype = {pkgs, ...}: let
    voxtypePkgs = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system};
    unwrapped = voxtypePkgs.voxtype-vulkan-unwrapped.overrideAttrs {
      cargoDeps = let
        importCargoLock = pkgs.rustPlatform.importCargoLock.override {
          fetchgit = args: pkgs.fetchgit (args // {fetchSubmodules = false;});
        };
        openvinoHash = "sha256-ilmAcg1Owa5bBHvBs9qTcWKUPHxby3ZFrzDRqblHvgs=";
      in
        importCargoLock {
          lockFile = "${inputs.voxtype}/Cargo.lock";
          outputHashes = {
            "openvino-finder-0.11.0" = openvinoHash;
            "openvino-genai-0.11.0" = openvinoHash;
            "openvino-genai-sys-0.11.0" = openvinoHash;
            "openvino-sys-0.11.0" = openvinoHash;
          };
        };
    };
    package = voxtypePkgs.vulkan.overrideAttrs {paths = [unwrapped];};
    models = import "${inputs.voxtype}/nix/models.nix";
  in {
    imports = [inputs.voxtype.homeManagerModules.default];

    programs.voxtype = {
      enable = true;
      inherit package;
      service.enable = true;
    };

    home.file.".local/share/voxtype/models/ggml-small.en.bin".source = pkgs.fetchurl {inherit (models."small.en") url hash;};
  };
}
