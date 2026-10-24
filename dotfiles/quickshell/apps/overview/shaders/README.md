# Overview shaders

Quickshell loads the compiled `downscale.frag.qsb`, not `downscale.frag`.
Rebuild it in this directory after every change to `downscale.frag`:

```sh
nix shell nixpkgs#qt6.qtshadertools -c qsb --glsl "150,300 es" -o downscale.frag.qsb downscale.frag
```

The registry `nixpkgs` is the stable input, so `qsb` matches the Qt that Quickshell runs on.
