{...}: {
  flake.modules.homeManager.ai-agents = {
    pkgs,
    inputs,
    config,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };

    piAgentDir = "${config.home.homeDirectory}/.pi/agent";

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
      ];

      dotfiles.configFiles = [
        (aiAgent "ponte/config.toml" "ponte.toml")
        (aiAgent "ponte/AGENTS.md" "AGENTS.md")
        (aiAgent "ponte/skills" "skills")
      ];

      dotfiles.homeFiles = [
        (aiAgent "${piAgentDir}/settings.json" "pi/settings.json")
        (aiAgent "${piAgentDir}/starline.json" "pi/starline.json")
        (aiAgent "${piAgentDir}/models.json" "pi/models.json")
        (aiAgent "${piAgentDir}/keybindings.json" "pi/keybindings.json")
        (aiAgent "${piAgentDir}/extensions" "extensions")
      ];
    };
  };
}
