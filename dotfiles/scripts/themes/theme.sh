#!/usr/bin/env bash
# Theme switcher: darkman + matugen, using the current wallpaper if none given.

set -euo pipefail

# ---- deps ----
for cmd in darkman matugen noctalia dconf; do
	command -v "$cmd" >/dev/null 2>&1 || {
		echo "Error: missing dependency '$cmd' in PATH" >&2
		exit 1
	}
done

# ---- args ----
MODE="${1:-}"
REQ_WALL="${2:-}"

reload_gtk_apps() {
	local key=/org/gnome/desktop/interface/gtk-theme
	local current
	current=$(dconf read $key)
	dconf write $key "''"
	dconf write $key "$current"
}

usage() {
	echo "Usage: $(basename "$0") [light|dark] [optional:/path/to/wallpaper]"
	exit 1
}

[[ "$MODE" == "light" || "$MODE" == "dark" ]] || usage

WALLPAPER="${REQ_WALL:-$(noctalia msg wallpaper-get)}"
[[ -f "$WALLPAPER" ]] || {
	echo "Error: wallpaper '$WALLPAPER' not found" >&2
	exit 1
}

echo "Applying $MODE theme via darkman…"
darkman set "$MODE"

if [[ -n "$REQ_WALL" ]]; then
	echo "Setting wallpaper to '$WALLPAPER'…"
	noctalia msg wallpaper-set "$WALLPAPER"
fi

echo "Generating color scheme with matugen…"
matugen -m "$MODE" -t scheme-expressive --source-color-index 0 --show-colors image "$WALLPAPER"

reload_gtk_apps

echo "✅ Theme set successfully!"
