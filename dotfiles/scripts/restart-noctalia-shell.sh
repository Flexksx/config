#!/usr/bin/env bash
set -euo pipefail

pkill -f ".quickshell-" 2>/dev/null || true

sleep 0.5

nohup noctalia-shell &>/dev/null &
disown
