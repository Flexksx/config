# Contributes a binary cache (substituter + trusted public key) to the Nix
# configuration. Import it where the package that benefits from the cache
# lives, e.g. `(nix-cache { url = "cache.nixos-cuda.org"; key = "..."; })`.
{
  url,
  key,
}: {
  nix.settings = {
    substituters = ["https://${url}"];
    trusted-public-keys = [key];
  };
}
