#!/usr/bin/env bash
# 每次执行：本机 Maven 重新打包 + Docker 构建 + 后台启动容器（不附着日志）
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

if [[ -f "$here/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$here/.env"
  set +a
fi
export DOCKER_NETWORK="${DOCKER_NETWORK:-my-network}"

echo "[compose-up] Maven clean package (all modules)…"
chmod +x ./mvnw 2>/dev/null || true
./mvnw -B -ntp clean package -DskipTests

if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
  echo "[compose-up] 创建 Docker 网络: $DOCKER_NETWORK"
  docker network create "$DOCKER_NETWORK"
fi

export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS="${BUILDKIT_PROGRESS:-plain}"
export COMPOSE_PARALLEL_LIMIT="${COMPOSE_PARALLEL_LIMIT:-5}"
echo "[compose-up] docker compose up -d --build（后台）…"
docker compose up -d --build "$@"
echo "[compose-up] 完成。查看日志: docker compose logs -f [service]"
