#!/usr/bin/env bash
# 一键启动本目录下 Docker Compose（Nacos + 全部 SCA 服务 + 压测 traffic）
# 前置：已在 spring-insight 父工程执行 mvn clean install -DskipTests
set -euo pipefail
export LOCAL_M2_REPOSITORY="${LOCAL_M2_REPOSITORY:-$HOME/.m2/repository}"
export DOCKER_BUILDKIT=1
exec docker compose up --build "$@"
