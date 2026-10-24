#!/usr/bin/env bash

set -euo pipefail

# Workspace Preset Launcher
# Launches predefined workspace layouts with apps on specific workspaces

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/workspace-presets.conf"
LAUNCH_DELAY=0.5 # Delay between launching apps (seconds)

# Check dependencies
for cmd in hyprctl jq notify-send; do
	if ! command -v "$cmd" &>/dev/null; then
		echo "Error: Required command '$cmd' not found"
		exit 1
	fi
done

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
	notify-send -u critical "Workspace Presets" "Config file not found: $CONFIG_FILE"
	exit 1
fi

# Function to check if an app is running
is_running() {
	local class_name="$1"
	hyprctl clients -j | jq -e ".[] | select(.class == \"$class_name\")" >/dev/null 2>&1
}

# Function to launch app on specific workspace
launch_on_workspace() {
	local app_command="$1"
	local class_name="$2"
	local workspace="$3"
	local working_dir="${4:-}"

	echo "Launching $app_command (class: $class_name) on workspace $workspace"

	# Check if app is already running
	if is_running "$class_name"; then
		echo "  -> App already running, moving to workspace $workspace"
		hyprctl dispatch movetoworkspacesilent "$workspace,class:^($class_name)$"
		return 0
	fi

	# Prepare the command with working directory if specified
	local full_command="$app_command"
	if [[ -n "$working_dir" && -d "$working_dir" ]]; then
		# For apps that support opening directories (like code/cursor)
		full_command="$app_command $working_dir"
	fi

	# Launch app on specific workspace
	# Using workspace directive to open on specific workspace
	hyprctl dispatch exec "[workspace $workspace silent] $full_command"

	return 0
}

# Function to launch a preset
launch_preset() {
	local preset_name="$1"
	local app_count=0
	local launched_apps=()

	echo "Launching preset: $preset_name"
	notify-send "Workspace Presets" "Launching preset: $preset_name"

	# Read config and launch apps for this preset
	while IFS='|' read -r name cmd class workspace workdir; do
		# Skip comments and empty lines
		[[ "$name" =~ ^#.*$ || -z "$name" ]] && continue

		# Only process lines for this preset
		if [[ "$name" == "$preset_name" ]]; then
			launch_on_workspace "$cmd" "$class" "$workspace" "$workdir"
			launched_apps+=("$cmd")
			((app_count++))

			# Add delay between launches to avoid race conditions
			if [[ $app_count -gt 0 ]]; then
				sleep "$LAUNCH_DELAY"
			fi
		fi
	done <"$CONFIG_FILE"

	if [[ $app_count -eq 0 ]]; then
		notify-send -u critical "Workspace Presets" "No apps found for preset: $preset_name"
		exit 1
	fi

	echo "Launched $app_count app(s) for preset: $preset_name"
	notify-send "Workspace Presets" "Launched $app_count app(s) successfully"

	# Switch to the first workspace of the preset
	local first_workspace
	first_workspace=$(grep "^$preset_name|" "$CONFIG_FILE" | head -n1 | cut -d'|' -f4)
	if [[ -n "$first_workspace" ]]; then
		hyprctl dispatch workspace "$first_workspace"
	fi
}

# Main execution
if [[ $# -eq 0 ]]; then
	echo "Usage: $0 <preset_name>"
	echo ""
	echo "Available presets:"
	grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | cut -d'|' -f1 | sort -u | sed 's/^/  - /'
	exit 1
fi

launch_preset "$1"
