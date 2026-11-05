#!/usr/bin/env bash
set -euo pipefail

files=("$@")
if [ ${#files[@]} -eq 0 ]; then
	mapfile -t files < <(git ls-files -- '*.lua')
fi

status=0
for file in "${files[@]}"; do
	[ -f "$file" ] || continue
	line_number=0
	while IFS= read -r line || [ -n "$line" ]; do
		line_number=$((line_number + 1))
		stripped=$(printf '%s\n' "$line" | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g; s/\[\[[^]]*\]\]//g")
		if [[ $stripped == *--* ]]; then
			printf '%s:%s: comment found\n' "$file" "$line_number"
			status=1
		fi
	done <"$file"
done
exit "$status"
