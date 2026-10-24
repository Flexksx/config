{...}: {
  flake.modules.homeManager.terminal = {
    config,
    lib,
    pkgs,
    inputs,
    ...
  }: let
    fontFamily = "JetBrainsMono Nerd Font Mono";
    fontSize = 11;
    pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    cfg-script = pkgs.writeShellScriptBin "cfg" (builtins.readFile ../../dotfiles/scripts/cfg.sh);
    cursorTrailShader = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/sahaj-b/ghostty-cursor-shaders/main/cursor_tail.glsl";
      sha256 = "04m35iyvr7vk6j2m5mywrb6i3pw2qmbghp1gyab2fldx264j6h88";
    };
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
    ];

    dotfiles.configFiles = ["bat/config"];

    home.sessionVariables = {
      NH_FLAKE = "/home/${config.home.username}/config";
      OBSIDIAN_VAULT = lib.mkDefault "${config.home.homeDirectory}/Obsidian/obsidian-vault";
    };

    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        defaultKeymap = "viins";
        shellAliases = {
          pls = "sudo";
          sayhi = "echo 'Hello, world!'";
          gaccounts = "dbus-run-session -- env XDG_CURRENT_DESKTOP=GNOME gnome-control-center online-accounts";
          cat = "bat";
          gg = "gitui";
          ldk = "lazydocker";
        };
        history.size = 10000;
        history.ignoreAllDups = true;
        initContent = ''
          export E_GITHUB_TOKEN="$(gh auth token 2>/dev/null)"

          sudo-command-line() {
            [[ -z $BUFFER ]] && zle up-history
            if [[ $BUFFER == sudo\ * ]]; then
              LBUFFER="''${LBUFFER#sudo }"
            else
              LBUFFER="sudo $LBUFFER"
            fi
          }
          zle -N sudo-command-line
          bindkey "^[^[" sudo-command-line

          autoload -U +X bashcompinit && bashcompinit
          complete -o nospace -C terraform terraform

          function zle-keymap-select {
            zle reset-prompt
          }
          zle -N zle-keymap-select

          _cfg_completions() {
            local -a cmds
            cmds=(
              'stg:Stage changes (git add)'
              'upd:Pull, update flake.lock, commit'
              'rhm:Rebuild Home Manager'
              'rflk:Rebuild NixOS'
              'uhm:Sync config + Rebuild Home Manager'
              'uflk:Sync config + Rebuild NixOS'
              'all:Rebuild both (pass -u to sync first)'
              'clean:Garbage collect old generations'
              'rshl:Restart noctalia-shell'
            )
            case $CURRENT in
              2) _describe 'command' cmds ;;
              3) [[ $words[2] == all ]] && _arguments ':flag:(-u)' ;;
            esac
          }
          compdef _cfg_completions cfg

          sgj() { sg run --pattern "$1" --lang java "''${@:2}"; }
          sgp() { sg run --pattern "$1" --lang python "''${@:2}"; }
          sgn() { sg run --pattern "$1" --lang nix "''${@:2}"; }
        '';
      };

      eza = {
        enable = true;
        git = true;
        icons = "always";
        enableZshIntegration = true;
      };

      zoxide = {
        enable = true;
        options = ["--cmd cd"];
      };

      bat.enable = true;

      starship = {
        enable = true;
        enableZshIntegration = true;
        # config owned by noctalia template — dotfiles/starship/starship.toml
      };

      atuin = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          auto_sync = false;
          search_mode = "fuzzy";
          filter_mode = "global";
          style = "compact";
        };
      };

      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      neovim = {
        enable = true;
        withRuby = false;
        withPython3 = false;
        withNodeJs = false;
      };

      ghostty = {
        enable = true;
        package = pkgs-unstable.ghostty;
        enableZshIntegration = true;
        settings = {
          font-family = fontFamily;
          font-size = fontSize;
          background-opacity = 0.7;
          theme = "matugen";
          custom-shader = "${cursorTrailShader}";
          custom-shader-animation = true;
          window-inherit-working-directory = false;
          keybind = [
            "alt+y=text:y\r"
          ];
        };
      };
    };
  };
}
