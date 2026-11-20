#!/usr/bin/env bash

EXT_MON="HDMI-A-1"
SLACK_CLASS="Slack"
TELEGRAM_CLASS="org.telegram.desktop"

is_running() {
	hyprctl clients -j | jq -e ".[] | select(.class == \"$1\")" >/dev/null
}

move_apps() {
	TARGET_SLACK=$1
	TARGET_TG=$2

	if is_running "$SLACK_CLASS"; then
		hyprctl dispatch movetoworkspacesilent "$TARGET_SLACK,class:^($SLACK_CLASS)$"
	fi

	if is_running "$TELEGRAM_CLASS"; then
		hyprctl dispatch movetoworkspacesilent "$TARGET_TG,class:^($TELEGRAM_CLASS)$"
	fi
}

handle() {

	MONITOR_DATA=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$EXT_MON\")")

	if [ -n "$MONITOR_DATA" ]; then
		TRANSFORM=$(echo "$MONITOR_DATA" | jq '.transform')

		if [ "$TRANSFORM" -eq 1 ] || [ "$TRANSFORM" -eq 3 ]; then
			move_apps 4 4
		fi
	else
		move_apps 9 10
	fi
}

if ! command -v jq >/dev/null || ! command -v socat >/dev/null; then
	notify-send "Monitor Script" "Please install 'jq' and 'socat' for the script to work."
	exit 1
fi

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR"/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock | while read -r line; do
	case $line in
	monitoradded* | monitorremoved*) handle ;;
	esac
done
