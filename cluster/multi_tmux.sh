#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Usage: $0 <ip_list_file> [optional_command]"
	exit 1
fi

IP_LIST_FILE=$1
OPTIONAL_COMMAND=$2
USER="XXX"
PASS="XXX"
SESSION="ssh_multi"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
	tmux new-session -d -s "$SESSION" -n "main" "bash"
fi

mapfile -t ip_list < "$IP_LIST_FILE"

for ip in "${ip_list[@]}"; do
	[[ -z "$ip" || "$ip" =~ ^# ]] && continue
	SSH_CMD="sshpass -p '$PASS' ssh $SSH_OPTIONS $USER@$ip"
	WIN_NAME=$(echo "$ip" | tr '.' '_')

	if ! tmux list-windows -t "$SESSION" | grep -qE "^\s*[0-9]+:\s+$WIN_NAME\b"; then
		tmux new-window -t "$SESSION" -n "$WIN_NAME" "$SSH_CMD"
		tmux send-keys -t "$SESSION:$WIN_NAME" "sleep 1" C-m
		tmux send-keys -t "$SESSION:$WIN_NAME" "sudo -i" C-m
		tmux send-keys -t "$SESSION:$WIN_NAME" "$PASS" C-m
	fi

	if [ -n "$OPTIONAL_COMMAND" ]; then
		tmux send-keys -t "$SESSION:$WIN_NAME" "$OPTIONAL_COMMAND" C-m
	fi
done

