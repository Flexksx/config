{...}: {
  flake.modules.nixos.virtualisation = {...}: {
    virtualisation.docker.enable = true;
  };

  flake.modules.homeManager.virtualisation = {...}: {
    programs.zsh.shellAliases = {
      docker-clean = "docker system prune --volumes";
    };
  };
}
