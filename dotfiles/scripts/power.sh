#!/usr/bin/env bash
set -euo pipefail

export FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE=''

action=$(printf 'Cancel\nShutdown\nReboot\nSuspend\n' | fzf --no-sort --prompt='Power: ') || exit $?

case "$action" in
Shutdown) command=poweroff ;;
Reboot) command=reboot ;;
Suspend) command=suspend ;;
*) exit 0 ;;
esac

confirmation=$(printf 'Cancel\nYes\n' | fzf --no-sort --prompt="${action}? ") || exit $?
if [[ "$confirmation" == Yes ]]; then
	systemctl "$command"
fi
