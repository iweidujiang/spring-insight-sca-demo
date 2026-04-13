#!/usr/bin/env bash
# 一键启动本目录下 Docker Compose（SCA 各服务 + 压测 traffic；Nacos 需已在外部启动）
# 前置：spring-insight 已 mvn install；Nacos 容器 nacos-standalone 已在网络 my-network 上运行
set -euo pipefail
export LOCAL_M2_REPOSITORY="${LOCAL_M2_REPOSITORY:-$HOME/.m2/repository}"
export DOCKER_NETWORK="${DOCKER_NETWORK:-my-network}"
export DOCKER_BUILDKIT=1
if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
  echo "[compose-up] 创建 Docker 网络: $DOCKER_NETWORK"
  docker network create "$DOCKER_NETWORK"
fi
exec docker compose up --build "$@"
