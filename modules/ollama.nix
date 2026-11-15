{...}: let
  nix-cache = import ./_nix-cache.nix;
in {
  flake.modules.homeManager.ollama = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.ollama;
  in {
    options.ollama = {
      enable = lib.mkEnableOption "Ollama, a local LLM server";
      cuda = lib.mkEnableOption "CUDA (NVIDIA) acceleration for Ollama";
    };

    config = lib.mkMerge [
      {services.ollama.enable = cfg.enable;}

      (lib.mkIf cfg.enable {
        services.ollama = {
          environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";
          package = lib.mkIf cfg.cuda pkgs.ollama-cuda;
        };
      })

      (lib.mkIf (cfg.enable && cfg.cuda)
        (nix-cache {
          url = "cache.nixos-cuda.org";
          key = "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
        }))
    ];
  };
}
