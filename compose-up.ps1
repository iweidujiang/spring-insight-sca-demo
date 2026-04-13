# 一键启动本目录下 Docker Compose（Nacos + 全部 SCA 服务 + 压测 traffic）
# 前置：spring-insight 已安装到本地（在 spring-insight 父工程执行 mvn clean install -DskipTests）
# 用法: .\compose-up.ps1   或   .\compose-up.ps1 -d   （额外参数会传给 docker compose）
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposeArgs
)
$ErrorActionPreference = "Stop"
if (-not $env:LOCAL_M2_REPOSITORY) {
    $env:LOCAL_M2_REPOSITORY = (Join-Path $env:USERPROFILE ".m2\repository")
}
$env:DOCKER_BUILDKIT = "1"
& docker compose up --build @ComposeArgs
