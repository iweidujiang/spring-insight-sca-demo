# spring-insight-sca-demo

独立的 Spring Cloud Alibaba（Nacos）微服务演示工程，通过 Maven 依赖使用开源监测工具 **[Spring Insight](https://github.com/iweidujiang/spring-insight)**。

本 Compose **只起业务微服务**；`insight-server` 请另用 Docker / jar 单独启动。

## 架构

```text
本工程微服务（gateway / order / product / user / loyalty）
        │  依赖：spring-insight-agent-starter（Maven Central 或本地）
        │  配置：spring.insight.server-url → 宿主机上的 Server
        ▼
外部 insight-server:9966   ← 你先单独启动（compose.dev 本地构建 / GHCR / jar）
```

## 前置条件

1. **JDK 21**、Docker Compose v2  
2. **本机已启动 Nacos**（本 Demo **不再**用 compose 拉起 Nacos）  
3. **已单独启动 Spring Insight Server**（本 Demo 不包含 Server）

**开发联调（测本机改过的 Server / sqlite）：** 在 `spring-insight` 仓库根目录：

```bash
cd D:/a-github-project/spring-insight
mvn -pl insight-server -am package -DskipTests
docker compose -f compose.dev.yaml up -d --build
# 可选：$env:INSIGHT_STORAGE_MODE="file"|"memory"|"sqlite"
curl -sS http://localhost:9966/api/v1/health
```

**已发布镜像：**

```bash
docker run --rm -p 9966:9966 \
  -e SPRING_INSIGHT_SERVER_STORAGE_MODE=file \
  -e SPRING_INSIGHT_SERVER_STORAGE_FILE_PATH=/data/spans.json \
  -v spring-insight-data:/data \
  ghcr.io/iweidujiang/spring-insight-server:0.3.2
```

4. 业务侧解析 `spring-insight-agent-starter:0.3.2`（与 Insight `agent.version` 对齐；可直接从 Maven Central 拉取）：

```bash
# 仅当本地改过 Agent 时才需要：
# cd D:/a-github-project/spring-insight
# git checkout main
# mvn -pl spring-insight-agent-starter -am install -DskipTests -Dskip.ui=true
```

正式环境使用 Central 已发布版本即可。  
5. 配置 `.env`：

```bash
cd spring-insight-sca-demo
cp .env.example .env
# 编辑：MAVEN_REPO、DOCKER_NETWORK（默认 my-network）
```

| 变量 | 含义 |
|------|------|
| `MAVEN_REPO` | Maven **localRepository**（构建镜像时注入，解析 Starter） |
| `INSIGHT_SERVER_URL` | 容器内上报地址，默认 `http://host.docker.internal:9966` |
| `INSIGHT_INGEST_TOKEN` | 与 Server `ingest-token` 一致；Server 开启上报鉴权时必填（`compose.dev` 默认 `change-me`） |
| `DOCKER_NETWORK` | 与 Nacos 相同的外部网络（默认 `my-network`） |
| `NACOS_SERVER_ADDR` | 容器内地址（默认 `nacos-standalone:8848`） |

> Windows 路径建议用正斜杠，例如 `D:/Java/mvn_repo`。  
> 若把 Server 容器加入同一 Docker 网并命名为 `insight-server`，可设 `INSIGHT_SERVER_URL=http://insight-server:9966`。

## 一键启动（Docker）

确认 Nacos 与 insight-server 已就绪后，在本工程根目录：

**推荐（端口被占用时会自动换到空闲端口）：**

```powershell
.\scripts\docker-up.ps1 -Build
# 需要造数 profile：
# .\scripts\docker-up.ps1 -Build -Traffic
```

脚本会写入 `.env.ports`（已 gitignore），并打印实际访问地址。仅探测端口：

```powershell
.\scripts\docker-up.ps1 -ResolveOnly
```

也可以直接 Compose：

```bash
docker compose up -d --build
```

停止（**不会**停掉外部 Nacos / insight-server）：

```bash
docker compose down
```

可选持续造数：

```bash
docker compose --env-file .env --env-file .env.ports --profile traffic up -d
```

## 访问地址

| 用途 | URL（默认） |
|------|-----|
| **Insight 控制台**（外部） | http://localhost:9966/ |
| 业务网关 | http://localhost:8080/ |
| 造数 | `curl "http://localhost:8080/order/create?userId=1&productId=1"` |
| RestTemplate 造数 | `curl "http://localhost:8080/order/ping-rt?productId=1"`（CLIENT `component=RestTemplate`，`remoteService=sca-product`） |
| RestClient 造数 | `curl "http://localhost:8080/order/ping-rc?productId=1"`（CLIENT `component=RestClient`；直连时 remoteService 为 host） |
| 告警 Webhook 收件箱 | `POST /insight-alert/webhook`（网关或 order）；查看：`curl http://localhost:8080/insight-alert/recent` |
| 外部 Nacos | http://localhost:38848/nacos |

```bash
curl -sS "http://localhost:9966/api/v1/health"
curl -sS "http://localhost:9966/api/v1/ui/services"
curl -sS "http://localhost:9966/api/v1/ui/dependencies"
```

造数后约等 5 秒（Agent 异步批量上报）再刷新控制台。

## 端口

| 服务 | 宿主机默认 | 环境变量 | 说明 |
|------|----------|----------|------|
| insight-server（外部） | 9966 | — | 本 compose 不管理 |
| sca-gateway | 8080 | `GATEWAY_HOST_PORT` | 业务入口 |
| sca-order | 8081 | `ORDER_HOST_PORT` | 可直连 |
| nacos-standalone（外部） | 38848 等 | — | 本机自行维护 |

容器内端口不变（gateway `18080`、order `18081` 等）；仅映射到本机的端口可换。

## 本机 IDE 启动

1. 确保本机 Maven 已能解析 `spring-insight-agent-starter`  
2. 单独启动 Insight（Docker 或 `java -jar`，端口 9966）  
3. 确保本机 Nacos 已映射到 `127.0.0.1:38848`  
4. 再启动本工程各模块：loyalty → product → user → order → gateway  
5. 造数：`curl "http://localhost:18080/order/create?userId=1&productId=1"`  
6. 打开 http://localhost:9966/

### 验证 Insight ↔ Micrometer（sca-order）

`sca-order` 已加 `actuator` + `micrometer-registry-prometheus`。

```powershell
curl "http://localhost:8080/order/create?userId=1&productId=1"
curl -s "http://localhost:8081/actuator/prometheus" | Select-String "spring_insight"
```

期望看到 `spring_insight_spans_accepted_total`、`spring_insight_span_seconds_*`、`spring_insight_reporter_queue_size` 等。  
同时打开 http://localhost:9966/ 应仍有拓扑/链路（与 Prometheus 互补）。

## 业务侧如何接入 Insight（本工程已配置）

```xml
<dependency>
  <groupId>io.github.iweidujiang</groupId>
  <artifactId>spring-insight-agent-starter</artifactId>
  <version>0.3.2</version>
</dependency>
```

```yaml
spring:
  application:
    name: sca-order
  insight:
    server-url: http://localhost:9966
    # Docker profile 默认 host.docker.internal:9966，可由 INSIGHT_SERVER_URL 覆盖
```

无需 `@EnableSpringInsight`。

## Docker 构建说明

- 构建 context 为本仓库根目录；通用脚本为 `Dockerfile.service`。  
- 通过 Compose `additional_contexts.m2repo` 注入本机 Maven 仓库，从而解析 `spring-insight-agent-starter`。  
- **本 compose 不再包含 insight-server**；开发用 `compose.dev.yaml`，或用 GHCR / jar 单独启动。

## 说明

- **存储只在 insight-server**：不要把 `spring.insight.server.storage.*` 写到各微服务。业务侧只需 `server-url`。  
- 升级 Agent：改 `spring.insight.version` 后本地 `mvn install`，再重建本 Demo 镜像即可。
