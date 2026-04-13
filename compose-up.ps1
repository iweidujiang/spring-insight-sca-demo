# 一键启动本目录下 Docker Compose（SCA 各服务 + 压测 traffic；Nacos 需已在外部启动）
# 前置：spring-insight 已 mvn install；Nacos 容器 nacos-standalone 已在网络 my-network 上运行
# 用法: .\compose-up.ps1   或   .\compose-up.ps1 -d
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposeArgs
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

# 先读取本目录 .env（与 docker compose 行为一致，便于配置 MAVEN_LOCAL_REPOSITORY=D:/java/mvn_repo）
$envFile = Join-Path $here ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim().Trim('"')
        switch ($key) {
            "MAVEN_LOCAL_REPOSITORY" { $env:MAVEN_LOCAL_REPOSITORY = $val }
            "LOCAL_M2_REPOSITORY" { $env:LOCAL_M2_REPOSITORY = $val }
            "DOCKER_NETWORK" { $env:DOCKER_NETWORK = $val }
        }
    }
}

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

$m2 = $env:MAVEN_LOCAL_REPOSITORY
if (-not (Test-Path $m2)) {
    Write-Error "[compose-up] Maven 本地库路径不存在: $m2 （请检查 .env 中 MAVEN_LOCAL_REPOSITORY 或 settings.xml localRepository）"
}
$insightPath = Join-Path $m2 "io\github\iweidujiang"
if (-not (Test-Path $insightPath)) {
    Write-Warning "[compose-up] 未找到 $insightPath ，请在 spring-insight 目录执行 mvn install -DskipTests"
} else {
    Write-Host "[compose-up] MAVEN_LOCAL_REPOSITORY=$m2 （已检测到 io/github/iweidujiang）"
}

# 若网络不存在则创建（与 nacos --network my-network 对齐）
docker network inspect $env:DOCKER_NETWORK 2>$null | Out-Null
if (-not $?) {
    Write-Host "[compose-up] 创建 Docker 网络: $($env:DOCKER_NETWORK)"
    docker network create $env:DOCKER_NETWORK
}

$env:DOCKER_BUILDKIT = "1"
if (-not $env:BUILDKIT_PROGRESS) { $env:BUILDKIT_PROGRESS = "plain" }
if (-not $env:COMPOSE_PARALLEL_LIMIT) { $env:COMPOSE_PARALLEL_LIMIT = "1" }

Write-Host "[compose-up] 首次构建若曾失败，建议: docker compose build --no-cache"
& docker compose up --build @ComposeArgs
