#!/usr/bin/env bash

BAL_CPU="50c:0%,54c:8%,58c:17%,66c:40%,78c:69%,83c:85%,86c:90%,98c:100%"
BAL_GPU="50c:0%,54c:4%,58c:13%,70c:38%,81c:69%,86c:81%,91c:90%,98c:100%"

PERF_CPU="40c:0%,50c:15%,60c:35%,68c:55%,75c:75%,82c:90%,88c:100%,98c:100%"
PERF_GPU="40c:0%,50c:10%,60c:25%,68c:45%,75c:70%,82c:85%,88c:100%,98c:100%"

apply_curves() {
	local cpu=$1
	local gpu=$2
	local label=$3

	local target_profile="Balanced"
	if [ "$label" = "Performance" ]; then
		target_profile="Performance"
	fi

	asusctl fan-curve --mod-profile "$target_profile" --fan cpu --data "$cpu"
	asusctl fan-curve --mod-profile "$target_profile" --fan gpu --data "$gpu"

	asusctl fan-curve --mod-profile "$target_profile" --enable-fan-curves true

	echo "Applied $label fan curves to Asus profile: $target_profile"
}

CURRENT_PROFILE=$(powerprofilesctl get)
if [ "$CURRENT_PROFILE" = "performance" ]; then
	apply_curves "$PERF_CPU" "$PERF_GPU" "Performance"
else
	apply_curves "$BAL_CPU" "$BAL_GPU" "Balanced"
fi

dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/UPower/PowerProfiles'" |
	while read -r line; do
		if echo "$line" | grep -q "ActiveProfile"; then
			sleep 1
			NEW=$(powerprofilesctl get)
			if [ "$NEW" = "performance" ]; then
				apply_curves "$PERF_CPU" "$PERF_GPU" "Performance"
			else
				apply_curves "$BAL_CPU" "$BAL_GPU" "Balanced/Quiet"
			fi
		fi
	done
