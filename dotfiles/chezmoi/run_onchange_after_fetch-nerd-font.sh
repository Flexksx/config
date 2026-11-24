#!/bin/sh
set -eu

font_url="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.5.0/patched-fonts/JetBrainsMono/Ligatures/JetBrainsMonoNerdFontMono-Regular.ttf"
font_name="JetBrainsMonoNerdFontMono-Regular.ttf"

case ${PREFIX:-} in
*/com.termux/*)
	mkdir -p "$HOME/.termux"
	curl -fL --retry 3 -o "$HOME/.termux/font.ttf" "$font_url"
	termux-reload-settings
	exit 0
	;;
esac

case $HOME in
*/var/mobile/Containers/Data/Application/*)
	mkdir -p "$HOME/Documents/Fonts"
	curl -fL --retry 3 -o "$HOME/Documents/Fonts/$font_name" "$font_url"
	config --fonts
	config -n "$font_name" -g
	;;
esac
