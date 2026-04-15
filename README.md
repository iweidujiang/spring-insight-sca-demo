# spring-insight-sca-demo

基于 **Spring Cloud Alibaba（Nacos）** 的多服务示例工程，演示微服务接入 **Spring Insight** 后的链路追踪、服务拓扑与监控控制台。

与 **`spring-insight`** 仓库为独立工程：本 demo 仅展示接入方式；发版与依赖版本以各仓库为准。

## 功能概览

| 能力 | 说明 |
|------|------|
| 注册发现 | Nacos；业务容器与 Nacos 使用同一 Docker 网络（默认 `my-network`） |
| 流量入口 | **sca-gateway**（8080），路由到 order / product / user / loyalty |
| Spring Insight | 各服务引入 `spring-insight-spring-boot-starter`；**控制台与 Collector API 部署在 sca-order** |
| 控制台访问 | 推荐 **经网关**：`http://localhost:8080/spring-insight/`；亦可直连 order：`http://localhost:8081/spring-insight/` |
| 演示数据 | `scripts/smoke-traffic.ps1` / `smoke-traffic.sh` 经网关批量调用下单接口 |

## 服务与端口

| 模块 | 端口 | 说明 |
|------|------|------|
| sca-gateway | 8080 | Spring Cloud Gateway；路由使用 `lb://` 时需依赖 **`spring-cloud-starter-loadbalancer`**；Insight 使用 WebFlux 采集入口请求 |
| sca-order | 8081 | 下单、OpenFeign；**Insight 控制台与 `/api/v1/**` 控制台 API** |
| sca-product | 8082 | 商品价格 |
| sca-user | 8083 | 用户；Feign 调用 loyalty |
| sca-loyalty | 8084 | 积分 |

**Nacos**：不在本仓库 compose 内。需自行启动实例，容器名建议 `nacos-standalone`，与业务容器同网；注册中心地址在 `application-docker.yml` 中为 `nacos-standalone:8848`。本机调试时可在 `application.yml` 中把 `server-addr` 指向宿主映射端口（如 `127.0.0.1:38848`）。

## 环境要求

- JDK 21、Docker、Docker Compose v2  
- 已创建并与 Nacos 共用的 Docker 网络（默认 **`my-network`**，可通过 `.env` 中 **`DOCKER_NETWORK`** 修改）  
- 可选：将 `.env.example` 复制为 **`.env`**，填写 **`NACOS_USERNAME`**、**`NACOS_PASSWORD`** 与 Nacos 控制台一致  

## 启动方式

**可选持续压测容器**：`docker-compose.yml` 中的 **`traffic`** 已配置 **`profiles: ["traffic"]`**，默认 **`docker compose up` 不会启动**，避免未手动调接口却持续产生链路。需要与旧版相同的后台请求时执行：`docker compose --profile traffic up -d`。

### 脚本（推荐）

在仓库根目录执行：

- Windows：`.\compose-up.ps1`  
- Linux / macOS：`chmod +x ./compose-up.sh && ./compose-up.sh`  

脚本会执行 **`mvnw clean package -DskipTests`**，再 **`docker compose up -d --build`**。完成后用 **`docker compose logs -f [服务名]`** 查看日志。

### 手动（等价）

```bash
cd spring-insight && ./mvnw -B -ntp clean install -DskipTests
cd ../spring-insight-sca-demo && ./mvnw -B -ntp clean package -DskipTests
docker network create my-network 2>/dev/null || true
docker compose up -d --build
```

（Windows 可将 `./mvnw` 换为 `mvnw.cmd`。）

## 使用说明

### 打开控制台

- **网关入口（推荐）**：<http://localhost:8080/spring-insight/>  
- **直连 order**：<http://localhost:8081/spring-insight/>  
- 兼容重定向：<http://localhost:8081/insight-ui> → 上述前缀根路径  

网关已将 **`/spring-insight/**`** 与 **`/api/v1/**`** 转发到 **sca-order**，与内置前端 `base` 及 `spring.insight.ui-base-path` 一致。

### 产生示例流量

在 **`spring-insight-sca-demo`** 目录：

```powershell
.\scripts\smoke-traffic.ps1
.\scripts\smoke-traffic.ps1 -Count 80 -BaseUrl "http://localhost:8080"
```

```bash
chmod +x ./scripts/smoke-traffic.sh
./scripts/smoke-traffic.sh 50
BASE_URL=http://localhost:8080 ./scripts/smoke-traffic.sh 80
```

默认请求：`GET {网关}/order/create?userId=1&productId=1`（经网关会走 product、user、loyalty 等调用）。随后在控制台查看 **链路 / 拓扑**。

若脚本报 **HTTP 503**：先确认网关已引入 **`spring-cloud-starter-loadbalancer`**（`lb://` 路由依赖它；仅有 Nacos 注册信息不够）。脚本会先等待并对 503 重试；若仍失败再核对 Nacos 中 **`sca-order`** 实例与健康状态。

### 业务路由（经网关）

| 前缀 | 目标服务 |
|------|-----------|
| `/order/**` | sca-order |
| `/product/**` | sca-product |
| `/user/**` | sca-user |
| `/loyalty/**` | sca-loyalty |

### 配置说明（摘要）

| 配置项 | 含义 |
|--------|------|
| `spring.insight.ui-base-path` | 控制台 SPA 与静态资源 URL 前缀，需与 Starter 内嵌前端构建一致；本 demo 为 **`/spring-insight`** |
| `DOCKER_NETWORK`（`.env`） | 与 Nacos、业务容器共用的外部网络名 |
| `spring.cloud.gateway.server.webflux.routes` | 网关路由（见 `sca-gateway` 的 `application.yml`） |

## 数据说明

Trace / Span 等数据保存在 **运行控制台所在 JVM 的内存** 中（本 demo 为 **sca-order**）；进程重启后清空。

**拓扑与依赖**：控制台中的依赖边来自 Span 上的 **`remoteService`** 字段。Starter 会为 **OpenFeign 出站调用** 上报 CLIENT 型 Span（含 `sca-user`、`sca-product` 等目标服务名），调用 **`/order/create`** 并刷新仪表盘/拓扑页后即可看到 **sca-order → 下游服务** 的边。

## Compose 网络名 `demo_net`

`docker-compose.yml` 中的 **`demo_net`** 为 Compose 文件内逻辑名，通过 `external: true` 与 `name: ${DOCKER_NETWORK:-my-network}` 指向已存在的 Docker 网络，与 `docker run --network my-network` 的 Nacos 同属一张网。
