{...}: {
  flake.modules.homeManager.git = {pkgs, ...}: {
    home.packages = [
      pkgs.delta
      pkgs.gh
    ];

    xdg.configFile."git/nix.gitconfig".text = ''
      [credential]
          helper = ${pkgs.git.override {withLibsecret = true;}}/bin/git-credential-libsecret
    '';
  };
}
