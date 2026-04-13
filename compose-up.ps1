# 一键启动本目录下 Docker Compose（SCA 各服务 + 压测 traffic；Nacos 需已在外部启动）
# 前置：spring-insight 已 mvn install；Nacos 容器 nacos-standalone 已在网络 my-network 上运行
# 用法: .\compose-up.ps1   或   .\compose-up.ps1 -d
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposeArgs
)
$ErrorActionPreference = "Stop"
if (-not $env:LOCAL_M2_REPOSITORY) {
    $env:LOCAL_M2_REPOSITORY = (Join-Path $env:USERPROFILE ".m2\repository")
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
& docker compose up --build @ComposeArgs
