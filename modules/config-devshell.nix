{...}: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        just
        lefthook
        alejandra
        biome
        stylua
        rumdl
        shfmt
        taplo
        yamlfmt
      ];
    };
  };
}
