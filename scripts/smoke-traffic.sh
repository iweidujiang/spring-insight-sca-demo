#!/usr/bin/env bash
# 经网关反复调用下单接口，便于在 Spring Insight 控制台观察链路与拓扑。
set -euo pipefail
BASE_URL="${BASE_URL:-http://localhost:8080}"
COUNT="${1:-40}"
USER_ID="${USER_ID:-1}"
PRODUCT_ID="${PRODUCT_ID:-1}"
url="${BASE_URL}/order/create?userId=${USER_ID}&productId=${PRODUCT_ID}"
echo "[smoke-traffic] GET ${url}  x ${COUNT}"
for i in $(seq 1 "${COUNT}"); do
  code=$(curl -sS -o /dev/null -w "%{http_code}" "${url}")
  echo "  #${i} HTTP ${code}"
done
