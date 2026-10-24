#!/usr/bin/env bash
set -euo pipefail

# Default flake path, but allow override via environment variable
FLAKE_PATH="${FLAKE:-$HOME/config}"

sync_config() {
	git -C "$FLAKE_PATH" pull --rebase
	nix flake update --flake "$FLAKE_PATH"
	git -C "$FLAKE_PATH" add flake.lock
	git -C "$FLAKE_PATH" commit -m "manual deps bump - $(date '+%Y-%m-%d %H:%M:%S')"
	git -C "$FLAKE_PATH" push
}

show_help() {
	echo "Usage: cfg <command> [options]"
	echo "Commands:"
	echo "  stg        - Stage changes (git add)"
	echo "  upd        - Pull from GitHub, update flake.lock, commit"
	echo "  rhm        - Rebuild Home Manager (nh)"
	echo "  rflk       - Rebuild NixOS (nh)"
	echo "  uhm        - Update lock + Rebuild Home"
	echo "  uflk       - Update lock + Rebuild NixOS"
	echo "  all [-u]   - Rebuild both; -u syncs config first"
	echo "  clean      - Garbage collect old generations"
	echo "  rshl       - Restart noctalia-shell"
}

case "${1:-}" in
stg)
	git -C "$FLAKE_PATH" add .
	;;
upd)
	sync_config
	;;
rhm)
	nh home switch "$FLAKE_PATH"
	;;
rflk)
	nh os switch "$FLAKE_PATH"
	;;
uhm)
	sync_config && nh home switch "$FLAKE_PATH"
	;;
uflk)
	sync_config && nh os switch "$FLAKE_PATH"
	;;
all)
	[[ "${2:-}" == "-u" ]] && sync_config
	nh os switch "$FLAKE_PATH" && nh home switch "$FLAKE_PATH"
	;;
clean)
	nh clean all --keep 5
	;;
rshl)
	bash "$HOME/config/dotfiles/scripts/restart-noctalia-shell.sh"
	;;
*)
	show_help
	exit 1
	;;
esac
