#!/usr/bin/env bash
set -euo pipefail

TARGET_SCRIPT="./ring_25g.sh"
RUN=1

while true; do
	echo "========== Run #$RUN =========="
	"$TARGET_SCRIPT"
	((RUN++))
done
