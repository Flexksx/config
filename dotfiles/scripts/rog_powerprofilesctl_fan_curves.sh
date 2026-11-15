#!/usr/bin/env bash

declare -A ASUS_PROFILE_FOR_PPD=(
	["performance"]=Performance
	["balanced"]=Balanced
	["power-saver"]=Balanced
)

declare -A CPU_CURVES=(
	["Balanced"]="50c:0%,54c:8%,58c:17%,66c:40%,78c:69%,83c:85%,86c:90%,98c:100%"
	["Performance"]="40c:0%,50c:15%,60c:35%,68c:55%,75c:75%,82c:90%,88c:100%,98c:100%"
)

declare -A GPU_CURVES=(
	["Balanced"]="50c:0%,54c:4%,58c:13%,70c:38%,81c:69%,86c:81%,91c:90%,98c:100%"
	["Performance"]="40c:0%,50c:10%,60c:25%,68c:45%,75c:70%,82c:85%,88c:100%,98c:100%"
)

apply_curves() {
	local profile=$1

	asusctl fan-curve --mod-profile "$profile" --fan cpu --data "${CPU_CURVES[$profile]}"
	asusctl fan-curve --mod-profile "$profile" --fan gpu --data "${GPU_CURVES[$profile]}"
	asusctl fan-curve --mod-profile "$profile" --enable-fan-curves true
	echo "Applied fan curves to Asus profile: $profile"
}

apply_current_profile() {
	local ppd_profile asus_profile

	ppd_profile=$(powerprofilesctl get)
	asus_profile=${ASUS_PROFILE_FOR_PPD[$ppd_profile]:-Balanced}
	apply_curves "$asus_profile"
}

apply_current_profile

dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/UPower/PowerProfiles'" |
	while read -r line; do
		if [[ $line == *ActiveProfile* ]]; then
			sleep 1
			apply_current_profile
		fi
	done
