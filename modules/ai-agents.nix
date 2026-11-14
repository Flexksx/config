{...}: let
  nix-cache = import ./_nix-cache.nix;
in {
  flake.modules.nixos.claude-code-cache = nix-cache {
    url = "claude-code.cachix.org";
    key = "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk=";
  };

  flake.modules.homeManager.ai-agents = {
    pkgs,
    inputs,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  in {
    config = {
      home.packages = [
        inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
        unstable.github-copilot-cli
        inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
        unstable.pi-coding-agent
        pkgs.nodejs
        unstable.bun
      ];
    };
  };
}
