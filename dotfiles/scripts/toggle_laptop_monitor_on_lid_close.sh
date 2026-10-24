#!/usr/bin/env bash

FILE="$HOME/config/dotfiles/hypr/lua/monitors.lua"
ACTION=$1 # Expected: "open" or "close"

MONITOR_DATA=$(hyprctl monitors -j)
EXTERNAL_COUNT=$(echo "$MONITOR_DATA" | jq '[.[] | select(.name | test("HDMI|DP-[0-9]"))] | length')
EDP_ACTIVE=$(
	echo "$MONITOR_DATA" | jq -e '.[] | select(.name == "eDP-1")' >/dev/null
	echo $?
) # 0 if found

function apply_changes() {
	notify-send "Display" "eDP-1 $1"
	hyprctl reload
}

if [[ "$ACTION" == "open" ]]; then
	if grep -q "local edp_disabled = true" "$FILE"; then
		sed -i 's/local edp_disabled = true/local edp_disabled = false/' "$FILE"
		apply_changes "Re-enabled"
	fi
elif [[ "$ACTION" == "close" ]]; then
	if [[ $EDP_ACTIVE -eq 0 ]] && [[ "$EXTERNAL_COUNT" -gt 0 ]]; then
		sed -i 's/local edp_disabled = false/local edp_disabled = true/' "$FILE"
		apply_changes "Disabled"
	fi
fi
