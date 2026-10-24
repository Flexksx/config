{lib, ...}: {
  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
    description = "home-manager configurations exposed as a flake output.";
  };

  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.unspecified);
    default = {};
    description = "Named module sets for NixOS and home-manager, keyed by namespace.";
  };
}
