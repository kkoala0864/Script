#! /bin/bash

if [ "$#" -lt 3 ]; then
	echo "./send_to_all ip_list ./file.tar /root"
	exit 1
fi

IP_LIST_FILE=$1
TAR_FILE=$2
REMOTE_DIR=$3

USER="XXX"
PASS="XXX"

TAR_FILENAME=$(basename "$TAR_FILE")
mapfile -t ip_list < "$IP_LIST_FILE"

for ip in "${ip_list[@]}"; do
	[[ -z "$ip" || "$ip" =~ ^# ]] && continue
	echo "===== send to $ip ====="

	echo "[1] send $TAR_FILE to $ip:$REMOTE_DIR"
	sshpass -p "$PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TAR_FILE" "$USER@$ip:$REMOTE_DIR"

	echo "[2] tar $TAR_FILENAME"
	sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$ip" "cd $REMOTE_DIR && tar -xf $TAR_FILENAME"

	echo "send $ip done"
	echo
done
