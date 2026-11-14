{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        just
        lefthook
        alejandra
        deadnix
        statix
        shellcheck
        stylua
        rumdl
        shfmt
        taplo
        yamlfmt
        unstable.bun
      ];
    };
  };
}
