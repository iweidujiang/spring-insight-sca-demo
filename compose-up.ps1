# 一键：本机 Maven 打包（若缺 jar）+ Docker 构建镜像（仅 COPY jar，秒级）+ compose up
# Nacos 需已在外部启动并接入 DOCKER_NETWORK（默认 my-network）
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposeArgs
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
Set-Location $here

$envFile = Join-Path $here ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim().Trim('"')
        if ($key -eq "DOCKER_NETWORK") { $env:DOCKER_NETWORK = $val }
    }
}
if (-not $env:DOCKER_NETWORK) { $env:DOCKER_NETWORK = "my-network" }

$requiredJars = @(
    "sca-gateway/target/sca-gateway-1.0.0-SNAPSHOT.jar",
    "sca-order/target/sca-order-1.0.0-SNAPSHOT.jar",
    "sca-user/target/sca-user-1.0.0-SNAPSHOT.jar",
    "sca-product/target/sca-product-1.0.0-SNAPSHOT.jar",
    "sca-loyalty/target/sca-loyalty-1.0.0-SNAPSHOT.jar"
)
$missing = @()
foreach ($rel in $requiredJars) {
    if (-not (Test-Path (Join-Path $here $rel))) { $missing += $rel }
}
if ($missing.Count -gt 0) {
    Write-Host "[compose-up] 缺少可运行 jar，将使用本机 Maven Wrapper 打包（走你的 settings.xml / 本地库，如 D:/java/mvn_repo）…"
    $mvnw = Join-Path $here "mvnw.cmd"
    if (-not (Test-Path $mvnw)) { Write-Error "[compose-up] 未找到 mvnw.cmd" }
    & $mvnw -B -ntp clean package -DskipTests
}

docker network inspect $env:DOCKER_NETWORK 2>$null | Out-Null
if (-not $?) {
    Write-Host "[compose-up] 创建 Docker 网络: $($env:DOCKER_NETWORK)"
    docker network create $env:DOCKER_NETWORK
}

$env:DOCKER_BUILDKIT = "1"
if (-not $env:BUILDKIT_PROGRESS) { $env:BUILDKIT_PROGRESS = "plain" }
# 镜像构建已很轻，可并行；若需串行可设 COMPOSE_PARALLEL_LIMIT=1
if (-not $env:COMPOSE_PARALLEL_LIMIT) { $env:COMPOSE_PARALLEL_LIMIT = "5" }

Write-Host "[compose-up] Docker 仅复制已打好的 jar，构建应很快；正在 compose up --build …"
& docker compose up --build @ComposeArgs
