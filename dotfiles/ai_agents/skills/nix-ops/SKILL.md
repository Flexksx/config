---
name: nix-ops
description: >
  Use when working with Nix, NixOS configuration, home-manager, flakes, or any .nix files.
  Covers the dendritic pattern, module system, and decision rules for where configuration belongs.
---

# Nix Operations

---

## Decision: Where Does Config Belong?

### NixOS — use when

- Config requires root or kernel-level access (services, systemd, udev, PAM, kernel params)
- Config must be system-wide and shared across all users (Docker, printing, networking, SSH daemon)
- Config concerns hardware directly (GPU drivers, CPU governor, Bluetooth, audio server)
- Config creates system users or groups

### Home-manager — use when

- Config is user-specific (dotfiles, shell, editor, theming)
- Packages are for one user only
- Config manages XDG dirs, session or environment variables
- Config defines user-level systemd units

### Overlays — use when

- An existing nixpkgs package needs to be patched or overridden globally
- The override must be visible to both NixOS and home-manager simultaneously

```nix
# Good — overlay patches an existing package
final: prev: {
  somePackage = prev.somePackage.override { enableFoo = true; };
}

# Bad — new packages go in pkgs/ as custom derivations, not in overlays
final: prev: {
  myNewTool = prev.buildGoModule { ... };
}
```

### Custom packages (`pkgs/`) — use when

- The package does not exist in nixpkgs
- You maintain the derivation yourself

---

## Nix Module System

Every `.nix` file that is not an entry point is a module.
A module is a function receiving module arguments and returning an attribute set with `imports`, `options`, and `config` keys.

```nix
{ config, pkgs, lib, ... }: {
  imports = [ ./other.nix ];
  options.myFeature.enable = lib.mkEnableOption "my feature";
  config = lib.mkIf config.myFeature.enable {
    environment.systemPackages = [ pkgs.hello ];
  };
}
```

### Module arguments

| Argument | Source | Contains |
|---|---|---|
| `config` | module system | final merged config values |
| `pkgs` | nixpkgs | all packages |
| `lib` | nixpkgs | utility functions |
| `inputs` | `specialArgs` / `extraSpecialArgs` | flake inputs |
| `outputs` | `specialArgs` / `extraSpecialArgs` | flake self-outputs |

Inject custom arguments without touching `specialArgs` using `_module.args`:

```nix
{ ... }: {
  _module.args.host = { username = "alice"; hostname = "my-host"; };
}
# Any downstream module can now declare: { host, ... }: { ... }
```

### Condition and precedence idioms

```nix
# mkIf — conditional config; never use bare `if` at module top level
config = lib.mkIf config.services.foo.enable {
  environment.systemPackages = [ pkgs.foo-client ];
};

# mkMerge — combine independent conditional blocks in one module
config = lib.mkMerge [
  (lib.mkIf config.foo.enable { ... })
  (lib.mkIf config.bar.enable { ... })
];

# mkDefault — value that can be overridden downstream
networking.hostName = lib.mkDefault "fallback-name";

# mkForce — value that cannot be overridden; use sparingly
nix.settings.experimental-features = lib.mkForce [ "nix-command" "flakes" ];
```

### Scoping idioms

```nix
# inherit — eliminates redundant key = value repetition
{ inherit inputs outputs; }         # instead of { inputs = inputs; outputs = outputs; }

# with — use only in package lists, never at module logic scope
environment.systemPackages = with pkgs; [ git curl wget ];
```

---

## Flake Conventions

### Follow shared inputs to prevent duplicate nixpkgs evaluations

```nix
home-manager.inputs.nixpkgs.follows = "nixpkgs";
hyprland-plugins.inputs.hyprland.follows = "hyprland";
```

### Always configure GC to prevent unbounded store growth

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 7d";
};
```

### Lock the flake registry and nix path to flake inputs

```nix
nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
nix.nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
```

---

## The Dendritic Pattern

### Concept

The dendritic pattern is an **aspect-oriented** approach to Nix configuration.
Every file configures one concern (e.g., `git`, `docker`, `wireguard`) across all configuration classes in that file.
`flake.nix` is a minimal, stable entry point.
New concerns are added by adding files — `flake.nix` never changes.

This is the inverse of class-oriented structure (all NixOS together, all home-manager together).

### Required tooling

Two tools make the pattern practical:

- **flake-parts** — replaces raw `outputs = { ... }` with the Nixpkgs module system applied to the flake itself, enabling modular flake outputs
- **import-tree** (`vic/import-tree`) — recursively discovers all `.nix` files under a directory and produces a single `flake-parts` module with `imports = [ ... ]`; files prefixed with `_` are excluded

```nix
# flake.nix — stable, never changes when adding features
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (
    inputs.import-tree [ ./modules ]
  );
}
```

### Module shape in dendritic

Each module under `modules/` is a flake-parts module.
It declares values for any configuration class it touches.

```nix
# modules/git.nix
{ ... }: {
  flake.modules.nixos.git = { pkgs, ... }: {
    programs.git.enable = true;
  };
  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      userName = "Alice";
      userEmail = "alice@example.com";
    };
  };
}
```

### Cross-module values without specialArgs

In a traditional flake, values pass between NixOS and home-manager via `specialArgs`.
In dendritic, every module reads from and writes to the **same top-level config**.
There is no threading — any module can declare an option and any other module can consume it.

```nix
# modules/_options.nix — declare shared options once
{ lib, ... }: {
  options.host = {
    username = lib.mkOption { type = lib.types.str; };
    hostname = lib.mkOption { type = lib.types.str; };
  };
}

# modules/networking.nix — consumes host.hostname set elsewhere
{ config, ... }: {
  flake.modules.nixos.networking = {
    networking.hostName = config.host.hostname;
  };
}
```

---

## Dendritic for Services and Ops

### Co-location pattern

Each service or application owns a `/nix` directory alongside its source code.
That directory contains flake-parts modules scoped to that service.
`import-tree` discovers and composes all of them.
The Nix store deduplicates shared dependencies automatically — two services depending on the same nixpkgs revision do not build or store it twice.

```text
repo/
  flake.nix                     # stable entry point
  services/
    api/
      src/                      # application code
      nix/
        package.nix             # derivation for the api binary
        service.nix             # NixOS systemd service module
        dev.nix                 # devShell for api development
    worker/
      src/
      nix/
        package.nix
        service.nix
        dev.nix
    database/
      nix/
        service.nix             # postgres configuration module
        backup.nix              # backup systemd timer
  infra/
    nix/
      networking.nix            # firewall, VPN, DNS
      users.nix                 # system users and SSH keys
      secrets.nix               # agenix or sops-nix config
```

### Service module shape

Each `nix/service.nix` is a self-contained flake-parts module.
It declares the NixOS service, its dependencies, and any shared options it exposes.

```nix
# services/api/nix/service.nix
{ config, lib, ... }: {
  options.services.api = {
    enable = lib.mkEnableOption "api service";
    port   = lib.mkOption { type = lib.types.port; default = 8080; };
  };

  flake.modules.nixos.api-service = { pkgs, config, ... }: lib.mkIf config.services.api.enable {
    systemd.services.api = {
      description = "API service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${config.flake.packages.x86_64-linux.api}/bin/api";
        DynamicUser = true;
      };
    };
    networking.firewall.allowedTCPPorts = [ config.services.api.port ];
  };
}
```

### devShells per service

Each service's `nix/dev.nix` declares a `perSystem.devShells.<service>` output.
Developers enter `nix develop .#api` to get only that service's toolchain.

```nix
# services/api/nix/dev.nix
{ ... }: {
  perSystem = { pkgs, ... }: {
    devShells.api = pkgs.mkShell {
      packages = [ pkgs.go pkgs.golangci-lint ];
    };
  };
}
```

### Packages per service

Each service's `nix/package.nix` declares `perSystem.packages.<service>`.
The Nix store deduplicates: if `api` and `worker` both depend on `openssl`, one store path is shared.

```nix
# services/api/nix/package.nix
{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.api = pkgs.buildGoModule {
      name = "api";
      src = ../src;
      vendorHash = "sha256-...";
    };
  };
}
```

### NixOS host configuration in dendritic

Hosts are also modules.
Each host module selects which service modules to enable.

```nix
# hosts/production/nix/host.nix
{ ... }: {
  flake.nixosConfigurations.production = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.api-service
      config.flake.modules.nixos.worker-service
      config.flake.modules.nixos.database
      config.flake.modules.nixos.networking
      { services.api.enable = true; services.worker.enable = true; }
    ];
  };
}
```

---

## References

- [Dendritic pattern — NixOS Discourse](https://discourse.nixos.org/t/the-dendritic-pattern/61271)
- [import-tree dendritic pattern](https://deepwiki.com/vic/import-tree/4.4-dendritic-pattern)
- [flake-parts options reference](https://flake.parts/options/flake-parts.html)
- [flake-parts multi-system: perSystem](https://flake.parts/system)
- [Dendrix — community dendritic configurations](https://vic.github.io/dendrix/Dendritic-Ecosystem.html)
