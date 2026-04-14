#!/usr/bin/env bash
# 经网关反复调用下单接口，便于在 Spring Insight 控制台观察链路与拓扑。
# 503：多为网关 LoadBalancer 在 lb://sca-order 下无实例（Nacos 未就绪或不在同一网络）。
set -euo pipefail
BASE_URL="${BASE_URL:-http://localhost:8080}"
COUNT="${1:-40}"
USER_ID="${USER_ID:-1}"
PRODUCT_ID="${PRODUCT_ID:-1}"
INITIAL_DELAY="${INITIAL_DELAY:-20}"
WAIT_READY="${WAIT_READY:-120}"
url="${BASE_URL}/order/create?userId=${USER_ID}&productId=${PRODUCT_ID}"

echo "[smoke-traffic] GET ${url}  x ${COUNT}"
if [[ "${INITIAL_DELAY}" -gt 0 ]]; then
  echo "[smoke-traffic] 等待 ${INITIAL_DELAY}s（Nacos 注册）…"
  sleep "${INITIAL_DELAY}"
fi

try_once() {
  curl -sS -o /dev/null -w "%{http_code}" --max-time 30 "${url}" || echo "000"
}

code="$(try_once)"
elapsed=0
if [[ "${code}" == "503" && "${WAIT_READY}" -gt 0 ]]; then
  echo "[smoke-traffic] 首轮 503，重试直至成功或超时 ${WAIT_READY}s（请确认 Nacos 与 sca-order 已注册）…"
  while [[ "${code}" == "503" && "${elapsed}" -lt "${WAIT_READY}" ]]; do
    sleep 2
    elapsed=$((elapsed + 2))
    code="$(try_once)"
  done
fi
if [[ "${code}" != "200" ]]; then
  echo "[smoke-traffic] 仍失败 HTTP ${code}" >&2
  exit 1
fi
echo "  #1 HTTP ${code}"

if [[ "${COUNT}" -lt 2 ]]; then
  exit 0
fi
for i in $(seq 2 "${COUNT}"); do
  code="$(try_once)"
  if [[ "${code}" != "200" ]]; then
    echo "[smoke-traffic] 请求 #${i} 失败 HTTP ${code}" >&2
    exit 1
  fi
  echo "  #${i} HTTP ${code}"
done
