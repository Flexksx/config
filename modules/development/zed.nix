{...}: {
  flake.modules.homeManager.zed = {
    pkgs,
    config,
    ...
  }: {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
      extensions = [
        "html"
        "toml"
        "rumdl"
        "qml"
        "tsgo"
        "lua"
        "git-firefly"
        "dockerfile"
        "sql"
        "vue"
        "svelte"
        "scss"
        "terraform"
        "kotlin"
        "xml"
        "latex"
        "nix"
        "jinja2"
        "gruvbox-material-mix"
        "java"
        "biome"
      ];
      userSettings = {
        vim_mode = true;
        buffer_font_family = ".ZedMono";
        buffer_font_weight = 500;
        theme = {
          mode = "system";
          light = "Gruvbox Material Light Mix";
          dark = "Gruvbox Material Dark Mix";
        };
        assistant = {
          enabled = true;
        };
        lsp = {
          nix = {
            binary = {
              path_lookup = true;
            };
          };
          lua-language-server = {
            binary = {
              path_lookup = true;
            };
          };
          "spring-boot" = {
            binary = {
              path = "${pkgs.jdk}/bin/java";
              arguments = [
                "-jar"
                config.programs.development.springBootLspJar
              ];
            };
          };
        };
        languages = {
          "Lua" = {
            language_servers = ["lua-language-server"];
            formatter = {
              external = {
                command = "stylua";
                arguments = ["-"];
              };
            };
            format_on_save = "on";
          };
          "Python" = {
            language_servers = [
              "ruff"
              "ty"
            ];
          };
        };
        load_direnv = "shell_hook";
      };
      userTasks = [
        {
          label = "Docker: Oxker UI";
          command = "oxker";
          use_new_terminal = true;
          allow_concurrent_runs = false;
        }
        {
          label = "K8s: K9s UI";
          command = "k9s";
          use_new_terminal = true;
          allow_concurrent_runs = false;
        }
      ];
      userKeymaps = [
        {
          bindings = {
            "ctrl-`" = "terminal_panel::ToggleFocus";
          };
        }
        {
          context = "Workspace";
          bindings = {
            "ctrl-shift-b" = "workspace::ToggleLeftDock";
            "ctrl-shift-a" = "agent::ToggleFocus";
            "ctrl-shift-e" = "workspace::FocusCenterPane";
            "ctrl-shift-t" = "project_panel::ToggleFocus";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl-shift-a" = "agent::ToggleFocus";
            "ctrl-shift-e" = "workspace::FocusCenterPane";
            "ctrl-shift-t" = "project_panel::ToggleFocus";
          };
        }
        {
          context = "Editor && VimControl && !VimWaiting && !menu";
          bindings = {
            "space" = null;
            "space r n" = "editor::Rename";
            "space r f" = "editor::Format";
          };
        }
      ];
    };
  };
}
