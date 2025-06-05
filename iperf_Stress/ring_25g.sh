#!/usr/bin/env bash
set -euo pipefail
IFS=$' \n\t'

SSH_USER="ACCOUNT"
PASS="PASSWORD"
DURATION=30

NODES=(
  "10.17.121.16"
  "10.17.121.52"
  "10.17.121.25"
  "10.17.121.47"
)
IPS=(
  "10.0.100.1 10.0.101.1 10.0.102.1 10.0.103.1"
  "10.0.100.2 10.0.101.2 10.0.102.2 10.0.103.2"
  "10.0.100.3 10.0.101.3 10.0.102.3 10.0.103.3"
  "10.0.100.4 10.0.101.4 10.0.102.4 10.0.103.4"
)

SERVER_CORES_START=0
SERVER_CORES_LEN=36
CLIENT_CORES_START=36
CLIENT_CORES_LEN=12

RESULT_DIR="result"

SSH_CMD=(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR)
SCP_CMD=(sshpass -p "$PASS" scp -q -o StrictHostKeyChecking=no)
remote_exec() { "${SSH_CMD[@]}" "$SSH_USER@$1" bash -s <<<"$2"; }
remote_copy() { "${SCP_CMD[@]}" "$1" "$2"; }

mk_ranges() {  # mk_ranges <start> <span> <num>
  local s=$1 span=$2 num=$3
  RANGES=()
  for ((i=0;i<num;i++)); do
    local start=$(( s + i*span ))
    local end=$(( start + span - 1 ))
    RANGES+=("${start}-${end}")
  done
  RANGE_IDX=0
}

cleanup() { for n in "${NODES[@]}"; do remote_exec "$n" "pkill iperf || true"; done; }
trap cleanup EXIT

[[ ${#NODES[@]} -eq ${#IPS[@]} ]] || { echo "NODES/IPS length mismatch" >&2; exit 1; }

stamp=$(date +%Y%m%d_%H%M%S)
LOGDIR="$RESULT_DIR/$stamp"
mkdir -p "$LOGDIR"; for i in "${!NODES[@]}"; do mkdir -p "$LOGDIR/node$((i+1))"; done

start_servers() {
  local node_ips=( $1 ) node=$2
  local count=${#node_ips[@]}
  local span=$(( SERVER_CORES_LEN / count ))
  mk_ranges $SERVER_CORES_START $span $count

  local cmd="rm -f /tmp/iperf_srv_* /tmp/iperf_cli_*; pkill iperf || true; "
  for ip in "${node_ips[@]}"; do
    local rng=${RANGES[$RANGE_IDX]}; RANGE_IDX=$((RANGE_IDX+1))
    echo "[server:$node] $ip cores $rng"
    cmd+="nohup taskset -c $rng iperf -s -B $ip > /dev/null 2>&1 & "
  done
  cmd+="exit 0"
  remote_exec "$node" "$cmd"
}

run_clients() {
  local src_ips=( $1 ) dst_ips=( $2 )
  local src_node=$3 dst_node=$4
  local count=${#src_ips[@]}
  local span=$(( CLIENT_CORES_LEN / count ))
  mk_ranges $CLIENT_CORES_START $span $count

  local cmd=""
  for ((i=0;i<count;i++)); do
    local sip=${src_ips[$i]} dip=${dst_ips[$i]}
    local rng=${RANGES[$RANGE_IDX]}; RANGE_IDX=$((RANGE_IDX+1))
    echo "[client:$src_node] $sip -> $dip cores $rng"
    cmd+="nohup taskset -c $rng iperf -B $sip -c $dip -t $DURATION -P 5 > /tmp/iperf_cli_${sip//./_}_to_${dip//./_}.log 2>&1 & "
  done
  cmd+="wait"
  remote_exec "$src_node" "$cmd"
}

echo "==> Start servers"
for i in "${!NODES[@]}"; do start_servers "${IPS[$i]}" "${NODES[$i]}"; done
sleep 2

echo "==> Start clients"
PIDS=()
for i in "${!NODES[@]}"; do next=$(( (i+1) % ${#NODES[@]} )); run_clients "${IPS[$i]}" "${IPS[$next]}" "${NODES[$i]}" "${NODES[$next]}" & PIDS+=($!); done
wait "${PIDS[@]}"

echo "==> Collect logs"
for i in "${!NODES[@]}"; do node=${NODES[$i]}; remote_copy "$SSH_USER@$node:/tmp/iperf_cli_*" "$LOGDIR/node$((i+1))/" || true; remote_exec "$node" "pkill iperf"; done

echo "Logs at $LOGDIR"

if [[ -x ./parse_result.sh ]]; then
  echo "-> Parsing results using ./parse_result.sh"
  ./parse_result.sh "$LOGDIR" "$RESULT_DIR/summary.log"
  echo "Summary saved to $RESULT_DIR/summary.log"
else
  echo "Warning: ./parse_result.sh not found or not executable"
fi
