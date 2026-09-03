#!/usr/bin/env bash
# 解析宿主机空闲端口并启动 docker compose（端口占用时自动上移）。
# 用法（仓库根目录）：
#   ./scripts/docker-up.sh
#   ./scripts/docker-up.sh --build
#   ./scripts/docker-up.sh --traffic
#   ./scripts/docker-up.sh --resolve-only

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD=0
TRAFFIC=0
RESOLVE_ONLY=0
INSIGHT_PREFER=9966
GATEWAY_PREFER=8080
ORDER_PREFER=8081
SPAN=40

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) BUILD=1; shift ;;
    --traffic) TRAFFIC=1; shift ;;
    --resolve-only) RESOLVE_ONLY=1; shift ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

port_busy() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "sport = :$p" 2>/dev/null | grep -q ":$p" && return 0
  elif command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1 && return 0
  else
    (echo >/dev/tcp/127.0.0.1/"$p") >/dev/null 2>&1 && return 0
  fi
  return 1
}

find_free() {
  local prefer="$1"
  local used="$2"
  local p end
  end=$((prefer + SPAN))
  for ((p = prefer; p <= end; p++)); do
    if [[ " $used " == *" $p "* ]]; then
      continue
    fi
    if ! port_busy "$p"; then
      echo "$p"
      return 0
    fi
  done
  echo "在 ${prefer}..${end} 范围内找不到空闲端口" >&2
  return 1
}

USED=""
INSIGHT_HOST_PORT="$(find_free "$INSIGHT_PREFER" "$USED")"
USED="$USED $INSIGHT_HOST_PORT"
GATEWAY_HOST_PORT="$(find_free "$GATEWAY_PREFER" "$USED")"
USED="$USED $GATEWAY_HOST_PORT"
ORDER_HOST_PORT="$(find_free "$ORDER_PREFER" "$USED")"

cat > .env.ports <<EOF
# 由 scripts/docker-up.sh 自动生成，勿手改；端口占用时会自动改选
INSIGHT_HOST_PORT=$INSIGHT_HOST_PORT
GATEWAY_HOST_PORT=$GATEWAY_HOST_PORT
ORDER_HOST_PORT=$ORDER_HOST_PORT
EOF

echo "宿主机端口映射："
echo "  insight-server  http://localhost:${INSIGHT_HOST_PORT}/"
echo "  sca-gateway     http://localhost:${GATEWAY_HOST_PORT}/"
echo "  sca-order       http://localhost:${ORDER_HOST_PORT}/ (容器内仍为 18081)"
if [[ "$INSIGHT_HOST_PORT" != "$INSIGHT_PREFER" || "$GATEWAY_HOST_PORT" != "$GATEWAY_PREFER" || "$ORDER_HOST_PORT" != "$ORDER_PREFER" ]]; then
  echo "提示：首选端口被占用，已自动切换（见 .env.ports）"
fi

if [[ "$RESOLVE_ONLY" -eq 1 ]]; then
  echo "已写入 .env.ports ，跳过启动。"
  exit 0
fi

ARGS=(--env-file .env --env-file .env.ports)
if [[ "$TRAFFIC" -eq 1 ]]; then
  ARGS+=(--profile traffic)
fi
ARGS+=(up -d)
if [[ "$BUILD" -eq 1 ]]; then
  ARGS+=(--build)
fi

echo "docker compose ${ARGS[*]}"
docker compose "${ARGS[@]}"

echo ""
echo "启动完成。访问示例："
echo "  控制台  http://localhost:${INSIGHT_HOST_PORT}/"
echo "  造数    curl \"http://localhost:${GATEWAY_HOST_PORT}/order/create?userId=1&productId=1\""
