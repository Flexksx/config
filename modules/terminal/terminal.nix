{...}: {
  flake.modules.homeManager.terminal = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }: let
    pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    cfg-script = pkgs.writeShellScriptBin "cfg" (builtins.readFile ../../dotfiles/scripts/cfg.sh);
  in {
    home.packages = with pkgs; [
      cfg-script
      inputs.turb.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.slackcli.packages.${pkgs.stdenv.hostPlatform.system}.default
      nh
      nvd
      nix-output-monitor
      nerd-fonts.jetbrains-mono
      cmatrix
      cbonsai
      gitui
      procs
      lazydocker
      oxker
      kubetui
      gping
      alejandra
      fzf
      xh
      chezmoi
      tree
      grim
      grimblast
      slurp
      killall
      wl-clipboard
      yt-dlp
      socat
      pass
      libnotify
      pciutils
      ripgrep
      fd
      appimage-run
      fastfetch
      pipes-rs
      dust
      broot
      ast-grep
      csvlens
      gophertube
      rumdl
      shfmt
      taplo
      yamlfmt
      lefthook
      just
      pandoc
      gdrive3
      eza
      zoxide
      atuin
      neovim
    ];

    home.sessionVariables = {
      NH_FLAKE = "/home/${config.home.username}/config";
      OBSIDIAN_VAULT = lib.mkDefault "${config.home.homeDirectory}/Obsidian/obsidian-vault";
    };

    programs = {
      bat = {
        enable = true;
        config = lib.mkForce {};
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      ghostty = {
        enable = true;
        package = pkgs-unstable.ghostty;
      };
    };
  };
}
