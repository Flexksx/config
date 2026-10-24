{...}: {
  flake.modules.homeManager.git = {
    pkgs,
    lib,
    config,
    ...
  }: {
    options.programs.git-config = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "Git user email address, set per host.";
      };
    };

    config.programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    config.programs.gh.enable = true;

    config.dotfiles.configFiles = ["gh/config.yml"];

    config.programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Flexksx";
          email = config.programs.git-config.email;
        };
        alias = {
          a = "add";
          acm = "!git add . && git commit -m";
          cm = "commit -m";
          co = "checkout";
          cob = "checkout -b";
          s = "status";
          br = "branch";
          nukepull = "!git clean -df && git reset --hard HEAD";
        };
        credential.helper = "${pkgs.git.override {withLibsecret = true;}}/bin/git-credential-libsecret";
        diff.colorMoved = "default";
        merge.conflictstyle = "diff3";
      };
    };
  };
}
