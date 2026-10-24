{...}: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        just
        lefthook
        alejandra
        stylua
        rumdl
        shfmt
        taplo
        yamlfmt
      ];
    };
  };
}
