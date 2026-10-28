#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
source tests/load/lib/metrics.sh

tmp_k6=$(mktemp)
cat > "$tmp_k6" <<'JSON'
{
  "metrics": {
    "http_reqs": {"values": {"rate": 25.5}},
    "extract_ok": {"values": {"rate": 0.987}},
    "http_req_duration": {"values": {"med": 42.1, "p(90)": 120.3, "p(95)": 210.7}}
  }
}
JSON

read -r t s p50 p90 p95 <<< "$(parse_k6_summary_json "$tmp_k6")"
[ "$t" = "25.50" ] || exit 1
[ "$s" = "98.7" ] || exit 1
[ "$p50" = "42.1" ] || exit 1
[ "$p90" = "120.3" ] || exit 1
[ "$p95" = "210.7" ] || exit 1

tmp_v=$(mktemp)
cat > "$tmp_v" <<'JSON'
{"throughput": 48.2, "success": 0.996, "latencies": {"50th": 42000000, "90th": 120000000, "95th": 210000000}}
JSON
read -r t2 s2 p502 p902 p952 <<< "$(parse_vegeta_report_json "$tmp_v")"
[ "$t2" = "48.20" ] || exit 1
[ "$s2" = "99.6" ] || exit 1
[ "$p502" = "42.0" ] || exit 1
[ "$p902" = "120.0" ] || exit 1
[ "$p952" = "210.0" ] || exit 1

rm -f "$tmp_k6" "$tmp_v"
echo "OK"
