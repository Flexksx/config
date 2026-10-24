#!/usr/bin/env bash
set -euo pipefail

mode="$(darkman get 2>/dev/null || echo dark)"

opts=(
	--paging=never
	--no-gitconfig
	--line-numbers
	--width=variable
	--file-decoration-style=none
	--hunk-header-decoration-style=none
	--hunk-header-style='line-number syntax'
)

if [ "$mode" = "light" ]; then
	exec delta "${opts[@]}" --light "$@"
fi

exec delta "${opts[@]}" --dark "$@"
