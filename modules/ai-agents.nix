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
        unstable.codex
        unstable.github-copilot-cli
        inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
        unstable.pi-coding-agent
        inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.ponte.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.nodejs
        unstable.bun
      ];
      dotfiles.configFiles = [
        (aiAgent "ponte/config.toml" "ponte.toml")
        (aiAgent "ponte/AGENTS.md" "AGENTS.md")
        (aiAgent "ponte/skills" "skills")
      ];
    };
  };
}
