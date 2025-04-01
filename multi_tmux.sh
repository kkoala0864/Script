#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Usage: $0 <IP1> [IP2] [IP3] ..."
	exit 1
fi

USER="xxx"
PASS="xxx"

SESSION="ssh_multi"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
	tmux new-session -d -s "$SESSION" -n "main" "bash"
fi

for ip in "$@"; do
	WIN_NAME="$ip"
	CMD="sshpass -p '$PASS' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $USER@$ip; bash"

	tmux new-window -t "$SESSION" -n "$WIN_NAME" bash -c "$CMD"
done

tmux select-window -t "$SESSION:0"
tmux attach-session -t "$SESSION"
