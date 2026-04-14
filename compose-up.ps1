# 每次执行：本机 Maven 重新打包 + Docker 构建镜像 + 后台启动容器（不附着日志）
# Nacos 需已在外部启动并接入 DOCKER_NETWORK（默认 my-network）
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ComposeArgs
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
Set-Location $here

$envFile = Join-Path $here ".env"
if (Test-Path -LiteralPath $envFile) {
    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -eq 0) { return }
        if ($line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim().Trim([char]0x22)
        if ($key -eq "DOCKER_NETWORK") {
            $env:DOCKER_NETWORK = $val
        }
    }
}
if (-not $env:DOCKER_NETWORK) {
    $env:DOCKER_NETWORK = "my-network"
}

Write-Host "[compose-up] Maven clean package (all modules)..."
$mvnw = Join-Path $here "mvnw.cmd"
if (-not (Test-Path -LiteralPath $mvnw)) {
    Write-Error "[compose-up] mvnw.cmd not found."
}
& $mvnw -B -ntp clean package -DskipTests

docker network inspect $env:DOCKER_NETWORK 2>$null | Out-Null
if (-not $?) {
    Write-Host "[compose-up] Creating Docker network: $($env:DOCKER_NETWORK)"
    docker network create $env:DOCKER_NETWORK
}

$env:DOCKER_BUILDKIT = "1"
if (-not $env:BUILDKIT_PROGRESS) {
    $env:BUILDKIT_PROGRESS = "plain"
}
if (-not $env:COMPOSE_PARALLEL_LIMIT) {
    $env:COMPOSE_PARALLEL_LIMIT = "5"
}

Write-Host "[compose-up] docker compose up -d --build (detached)..."
& docker compose up -d --build @ComposeArgs
Write-Host "[compose-up] Done. View logs: docker compose logs -f [service]"
