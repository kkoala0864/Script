#!/usr/bin/env bash
set -euo pipefail

LOGDIR="$1"
SUMMARY_FILE="$2"

extract_sr() {
  local log="$1"
  local sndG=0
  local line unit num

  line=$(grep -E '\[SUM\].*[0-9]+(\.[0-9]+)? (K|M|G)bits/sec' "$log" | tail -n1 || true)
  if [[ -n $line ]]; then
    read num unit <<<$(echo "$line" | grep -Eo '([0-9]+\.[0-9]+|[0-9]+) (K|M|G)bits/sec')
    sndG=$(awk "BEGIN{
      if (\"$unit\"==\"Gbits/sec\") print $num;
      else if (\"$unit\"==\"Mbits/sec\") print $num/1000;
      else if (\"$unit\"==\"Kbits/sec\") print $num/1000000;
      else print 0;
    }")
  else
    line=$(grep -E '\[[[:space:]]*[0-9]+\].*[0-9]+(\.[0-9]+)? (K|M|G)bits/sec' "$log" | tail -n1 || true)
    if [[ -n $line ]]; then
      read num unit <<<$(echo "$line" | grep -Eo '([0-9]+\.[0-9]+|[0-9]+) (K|M|G)bits/sec')
      sndG=$(awk "BEGIN{
        if (\"$unit\"==\"Gbits/sec\") print $num;
        else if (\"$unit\"==\"Mbits/sec\") print $num/1000;
        else if (\"$unit\"==\"Kbits/sec\") print $num/1000000;
        else print 0;
      }")
    fi
  fi
  echo "$sndG"
}

echo -e "\n===== Summary per node (Sender Gbit/s) ====="
printf "%-20s %-10s %-12s\n" "Timestamp" "Node" "Sender(Gbps)"

if [[ ! -f "$SUMMARY_FILE" ]]; then
  printf "%-20s %-10s %-12s\n" "Timestamp" "Node" "Sender(Gbps)" > "$SUMMARY_FILE"
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
for node_dir in "$LOGDIR"/node*/; do
  node_name=$(basename "$node_dir")
  sum_snd=0
  for f in "$node_dir"/iperf_cli_*.log; do
    [[ -f $f ]] || continue
    read snd < <(extract_sr "$f")
    sum_snd=$(awk -v a="$sum_snd" -v b="$snd" 'BEGIN{print a+b}')
  done
  printf "%-20s %-10s %12.2f\n" "$timestamp" "$node_name" "$sum_snd" | tee -a "$SUMMARY_FILE"
done

echo "" >> "$SUMMARY_FILE"
