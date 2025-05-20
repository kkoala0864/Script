#!/usr/bin/env bash
set -euo pipefail

USER="soit"
PASS="Syno1234"
DURATION=120

#NODES=("10.17.121.16" "10.17.121.126" "10.17.121.25" "10.17.121.47")
#IPS=(
#	"10.0.100.1 10.0.101.1 10.0.102.1 10.0.103.1"
#	"10.0.100.2 10.0.101.2 10.0.102.2 10.0.103.2"
#	"10.0.100.3 10.0.101.3 10.0.102.3 10.0.103.3"
#	"10.0.100.4 10.0.101.4 10.0.102.4 10.0.103.4"
#)
NODES=("10.17.121.16" "10.17.121.126")
IPS=(
	"10.0.100.1 10.0.101.1 10.0.102.1 10.0.103.1"
	"10.0.100.2 10.0.101.2 10.0.102.2 10.0.103.2"
)

RESULT_DIR="result"
timestamp_dir=$(date +%Y%m%d_%H%M%S)
LOGDIR="$RESULT_DIR/$timestamp_dir"
mkdir -p "$LOGDIR"

for i in "${!NODES[@]}"; do
  mkdir -p "$LOGDIR/node$((i+1))"
done

SSH_CMD=(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR)
SCP_CMD=(sshpass -p "$PASS" scp -q -o StrictHostKeyChecking=no)

start_servers() {
  local node_ips=($1)
  local node_name=$2
  local cmd="rm -f /tmp/iperf_srv_* /tmp/iperf_cli_*; "

  local total_cores=36
  local count=${#node_ips[@]}
  local cores_per_server=$(( total_cores / count ))
  local cpu_start=0

  for ip in "${node_ips[@]}"; do
    local cpu_end=$((cpu_start + cores_per_server - 1))
    local cpu_range="${cpu_start}-${cpu_end}"
    echo "-> On $node_name starting server for $ip using CPUs $cpu_range"
    echo "[server:$node_name] using cores $cpu_range"
    cmd+="nohup taskset -c ${cpu_range} iperf -s -B $ip > /dev/null 2>&1 & "
    cpu_start=$((cpu_end + 1))
  done

  cmd+="exit 0"
  "${SSH_CMD[@]}" "$USER@$node_name" bash -s <<<"$cmd"
}

run_clients() {
  local src_ips=($1)
  local dst_ips=($2)
  local src_node=$3
  local dst_node=$4
  local cmd=""

  local total_cores=12
  local count=${#src_ips[@]}
  local cores_per_client=$(( total_cores / count ))
  local cpu_start=36

  for ((idx=0; idx<count; idx++)); do
    local sip=${src_ips[$idx]}
    local dip=${dst_ips[$idx]}
    local cpu_end=$((cpu_start + cores_per_client - 1))
    local cpu_range="${cpu_start}-${cpu_end}"
    echo "[client:$src_node] $sip -> $dip using cores $cpu_range"
    cmd+="nohup taskset -c ${cpu_range} iperf -B $sip -c $dip -t $DURATION -P 5 > /tmp/iperf_cli_${sip//./_}_to_${dip//./_}.log 2>&1 & "
    cpu_start=$((cpu_end + 1))
  done

  cmd+="wait"
  echo "-> Running clients on $src_node -> $dst_node"
  "${SSH_CMD[@]}" "$USER@$src_node" bash -s <<<"$cmd"
}

for i in "${!NODES[@]}"; do
  start_servers "${IPS[$i]}" "${NODES[$i]}"
done

sleep 2

declare -a PIDS
for i in "${!NODES[@]}"; do
  next=$(( (i + 1) % ${#NODES[@]} ))
  run_clients "${IPS[$i]}" "${IPS[$next]}" "${NODES[$i]}" "${NODES[$next]}" & PIDS+=($!)
done
wait "${PIDS[@]}"

for i in "${!NODES[@]}"; do
  node_name=${NODES[$i]}
  echo "-> Collecting logs from $node_name"
  "${SCP_CMD[@]}" "$USER@$node_name:/tmp/iperf_cli_*" "$LOGDIR/node$((i+1))/"
  echo "-> Cleaning up iperf on $node_name"
  "${SSH_CMD[@]}" "$USER@$node_name" bash -s <<<"pkill iperf"
done

# Parse results using external script
if [[ -x ./parse_result.sh ]]; then
  echo "-> Parsing results using ./parse_result.sh"
  ./parse_result.sh "$LOGDIR" "$RESULT_DIR/summary.log"
else
  echo "Warning: ./parse_result.sh not found or not executable"
fi
