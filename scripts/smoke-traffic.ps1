<#
.SYNOPSIS
    经网关反复调用下单接口，便于在 Spring Insight 控制台观察链路与拓扑。

.PARAMETER BaseUrl
    网关根地址，默认 http://localhost:8080

.PARAMETER Count
    请求次数，默认 40

.PARAMETER UserId
    演示用户 ID，默认 1

.PARAMETER ProductId
    演示商品 ID，默认 1

.PARAMETER InitialDelaySeconds
    首轮请求前等待秒数，给 Nacos 注册留时间，默认 20

.PARAMETER WaitReadySeconds
    若首轮为 503，则每隔 2 秒重试直至成功或超过本秒数，默认 120；设为 0 则不等待
#>
param(
    [string] $BaseUrl = "http://localhost:8080",
    [int] $Count = 40,
    [long] $UserId = 1,
    [long] $ProductId = 1,
    [int] $InitialDelaySeconds = 20,
    [int] $WaitReadySeconds = 120
)
$ErrorActionPreference = "Stop"
$u = "$BaseUrl/order/create?userId=$UserId&productId=$ProductId"
Write-Host "[smoke-traffic] GET $u  x $Count"

if ($InitialDelaySeconds -gt 0) {
    Write-Host "[smoke-traffic] 等待 ${InitialDelaySeconds}s（Nacos 注册与 LoadBalancer 缓存）…"
    Start-Sleep -Seconds $InitialDelaySeconds
}

function Invoke-SmokeOnce {
    param([string]$Uri)
    try {
        $resp = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 30
        return @{ Ok = $true; StatusCode = $resp.StatusCode; Body = $resp.Content }
    }
    catch {
        $code = $null
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode
        }
        return @{ Ok = $false; StatusCode = $code; Error = $_.Exception.Message }
    }
}

$deadline = (Get-Date).AddSeconds([Math]::Max(0, $WaitReadySeconds))
$first = Invoke-SmokeOnce -Uri $u
if (-not $first.Ok -and $first.StatusCode -eq 503 -and $WaitReadySeconds -gt 0) {
    # 不用 @" "@：行首 [ 或全角引号在部分 PowerShell/编码下会触发解析错误
    Write-Host "[smoke-traffic] First request HTTP 503. Gateway cannot pick an instance for lb://sca-order."
    Write-Host "[smoke-traffic] If Nacos already lists sca-order: add spring-cloud-starter-loadbalancer to gateway (lb:// needs it)."
    Write-Host "[smoke-traffic] Retrying until success or ${WaitReadySeconds}s timeout..."
    while (-not $first.Ok -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        $first = Invoke-SmokeOnce -Uri $u
    }
}

if (-not $first.Ok) {
    throw "[smoke-traffic] 仍失败 (HTTP $($first.StatusCode))。$($first.Error)"
}

Write-Host "  #1 HTTP $($first.StatusCode)"
if ($Count -lt 2) {
    return
}
2..$Count | ForEach-Object {
    $r = Invoke-SmokeOnce -Uri $u
    if (-not $r.Ok) {
        throw "[smoke-traffic] 请求 #$_ 失败 HTTP $($r.StatusCode): $($r.Error)"
    }
    Write-Host "  #$($_) HTTP $($r.StatusCode)"
}
