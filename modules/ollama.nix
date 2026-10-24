{...}: {
  flake.modules.nixos-optional.ollama = {pkgs, ...}: {
    services.ollama = {
      package = pkgs.ollama-cuda;
      environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";
    };
  };
}
