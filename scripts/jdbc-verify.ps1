# JDBC 追踪造数（SCA demo）。需网关/order/user + insight-server；宿主机网关默认 8080
$ErrorActionPreference = "Stop"
$base = if ($env:GATEWAY_BASE) { $env:GATEWAY_BASE } else { "http://localhost:8080" }
Write-Host "Gateway base: $base"
curl.exe -sS "$base/order/jdbc-fast"
Write-Host ""
curl.exe -sS "$base/order/jdbc-slow?ms=600"
Write-Host ""
curl.exe -sS "$base/order/jdbc-error"
Write-Host ""
Write-Host "约 5 秒后打开 http://localhost:9966 查看链路（user 侧应有 JDBC CLIENT）"
