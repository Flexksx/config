#!/bin/sh
set -eu

mkdir -p "$HOME/.termux"
curl -fsSL "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/JetBrainsMonoNerdFontMono-Regular.ttf" -o "$HOME/.termux/font.ttf"
termux-reload-settings
