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
#>
param(
    [string] $BaseUrl = "http://localhost:8080",
    [int] $Count = 40,
    [long] $UserId = 1,
    [long] $ProductId = 1
)
$ErrorActionPreference = "Stop"
$u = "$BaseUrl/order/create?userId=$UserId&productId=$ProductId"
Write-Host "[smoke-traffic] GET $u  x $Count"
1..$Count | ForEach-Object {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing
    Write-Host "  #$($_) HTTP $($r.StatusCode)"
}
