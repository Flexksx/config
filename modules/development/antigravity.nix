{...}: {
  flake.modules.homeManager.antigravity = {inputs, ...}: {
    home.packages = [
      inputs.antigravity-nix.packages.x86_64-linux.google-antigravity-cli
    ];
  };
}
