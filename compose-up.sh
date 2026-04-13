#!/usr/bin/env bash
# 一键：本机 Maven 打包（若缺 jar）+ Docker 构建 + compose up
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

required=(
  "sca-gateway/target/sca-gateway-1.0.0-SNAPSHOT.jar"
  "sca-order/target/sca-order-1.0.0-SNAPSHOT.jar"
  "sca-user/target/sca-user-1.0.0-SNAPSHOT.jar"
  "sca-product/target/sca-product-1.0.0-SNAPSHOT.jar"
  "sca-loyalty/target/sca-loyalty-1.0.0-SNAPSHOT.jar"
)
need_mvn=0
for j in "${required[@]}"; do
  if [[ ! -f "$here/$j" ]]; then need_mvn=1; break; fi
done
if [[ "$need_mvn" -eq 1 ]]; then
  echo "[compose-up] 缺少 jar，正在本机 ./mvnw 打包（使用你的 Maven 配置）…"
  chmod +x ./mvnw 2>/dev/null || true
  ./mvnw -B -ntp clean package -DskipTests
fi

if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
  echo "[compose-up] 创建 Docker 网络: $DOCKER_NETWORK"
  docker network create "$DOCKER_NETWORK"
fi

export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS="${BUILDKIT_PROGRESS:-plain}"
export COMPOSE_PARALLEL_LIMIT="${COMPOSE_PARALLEL_LIMIT:-5}"
echo "[compose-up] MAVEN_LOCAL_REPOSITORY 由本机 mvn 使用，Docker 不再在容器内编译"
exec docker compose up --build "$@"
