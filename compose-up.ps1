# 一键启动本目录下 Docker Compose（SCA 各服务 + 压测 traffic；Nacos 需已在外部启动）
# 前置：spring-insight 已 mvn install；Nacos 容器 nacos-standalone 已在网络 my-network 上运行
# 用法: .\compose-up.ps1   或   .\compose-up.ps1 -d
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposeArgs
)
$ErrorActionPreference = "Stop"
Write-Host "[compose-up] 首次构建会较慢：Maven 需下载依赖，日志中会出现下载进度；未使用 -q 静默。"
Write-Host "[compose-up] 默认 COMPOSE_PARALLEL_LIMIT=1（串行构建镜像，日志更清晰）；可设置环境变量改为并行以加速。"
# Maven 本地库：优先 MAVEN_LOCAL_REPOSITORY，其次兼容 LOCAL_M2_REPOSITORY，最后默认 ~/.m2/repository
if (-not $env:MAVEN_LOCAL_REPOSITORY) {
    if ($env:LOCAL_M2_REPOSITORY) {
        $env:MAVEN_LOCAL_REPOSITORY = $env:LOCAL_M2_REPOSITORY
    } else {
        $env:MAVEN_LOCAL_REPOSITORY = (Join-Path $env:USERPROFILE ".m2\repository")
    }
}
if (-not $env:DOCKER_NETWORK) {
    $env:DOCKER_NETWORK = "my-network"
}
# 若网络不存在则创建（与 nacos --network my-network 对齐）
docker network inspect $env:DOCKER_NETWORK 2>$null | Out-Null
if (-not $?) {
    Write-Host "[compose-up] 创建 Docker 网络: $($env:DOCKER_NETWORK)"
    docker network create $env:DOCKER_NETWORK
}
$env:DOCKER_BUILDKIT = "1"
# 构建阶段输出完整日志（避免 BuildKit 折叠导致「像卡住」）
if (-not $env:BUILDKIT_PROGRESS) { $env:BUILDKIT_PROGRESS = "plain" }
# 默认串行构建各服务镜像，避免 5 个 Maven 同时跑占满 CPU/带宽、且均无输出
if (-not $env:COMPOSE_PARALLEL_LIMIT) { $env:COMPOSE_PARALLEL_LIMIT = "1" }
& docker compose up --build @ComposeArgs
