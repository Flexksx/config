{...}: {
  flake.modules.nixos-optional.ollama = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";
    };
  };
}
