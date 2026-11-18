{...}: {
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
    ];
  };
}
