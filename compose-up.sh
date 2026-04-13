#!/usr/bin/env bash
# 一键启动本目录下 Docker Compose（SCA 各服务 + 压测 traffic；Nacos 需已在外部启动）
# 前置：spring-insight 已 mvn install；Nacos 容器 nacos-standalone 已在网络 my-network 上运行
set -euo pipefail
# Maven 本地库：优先 MAVEN_LOCAL_REPOSITORY，其次兼容 LOCAL_M2_REPOSITORY，最后默认 ~/.m2/repository
export MAVEN_LOCAL_REPOSITORY="${MAVEN_LOCAL_REPOSITORY:-${LOCAL_M2_REPOSITORY:-$HOME/.m2/repository}}"
export DOCKER_NETWORK="${DOCKER_NETWORK:-my-network}"
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS="${BUILDKIT_PROGRESS:-plain}"
export COMPOSE_PARALLEL_LIMIT="${COMPOSE_PARALLEL_LIMIT:-1}"
echo "[compose-up] 首次构建较慢，Maven 会打印下载进度；COMPOSE_PARALLEL_LIMIT=${COMPOSE_PARALLEL_LIMIT}"
if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
  echo "[compose-up] 创建 Docker 网络: $DOCKER_NETWORK"
  docker network create "$DOCKER_NETWORK"
fi
exec docker compose up --build "$@"
