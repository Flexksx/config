{...}: {
  flake.modules.homeManager.ai-agents = {
    pkgs,
    inputs,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };

    aiAgent = target: source: {
      inherit target;
      source = "ai_agents/${source}";
    };
  in {
    config = {
      home.packages = [
        unstable.github-copilot-cli
        inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
        unstable.pi-coding-agent
        pkgs.nodejs
        unstable.bun
      ];
    };
  };
}
