#!/usr/bin/env bash

parse_k6_summary_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "0 0 0 0 0"
    return 0
  fi
  local throughput success p50 p90 p95
  throughput=$(jq -r '.metrics.http_reqs.values.rate // 0' "$file" 2>/dev/null | awk '{printf "%.2f", $1}')
  success=$(jq -r '.metrics.extract_ok.values.rate // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1 * 100}')
  p50=$(jq -r '.metrics.http_req_duration.values.med // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1}')
  p90=$(jq -r '.metrics.http_req_duration.values["p(90)"] // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1}')
  p95=$(jq -r '.metrics.http_req_duration.values["p(95)"] // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1}')
  echo "$throughput $success $p50 $p90 $p95"
}

parse_vegeta_report_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "0 0 0 0 0"
    return 0
  fi
  local throughput success p50 p90 p95
  throughput=$(jq -r '.throughput // 0' "$file" 2>/dev/null | awk '{printf "%.2f", $1}')
  success=$(jq -r '.success // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1 * 100}')
  p50=$(jq -r '.latencies["50th"] // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1 / 1e6}')
  p90=$(jq -r '.latencies["90th"] // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1 / 1e6}')
  p95=$(jq -r '.latencies["95th"] // 0' "$file" 2>/dev/null | awk '{printf "%.1f", $1 / 1e6}')
  echo "$throughput $success $p50 $p90 $p95"
}
