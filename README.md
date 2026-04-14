# spring-insight-sca-demo

Spring Cloud Alibaba（Nacos）多服务演示工程，用于本地压测 **Spring Insight** 的链路、拓扑与控制台。

**与 `spring-insight` 的关系**：二者为 **两个独立工程**（可分别建库、发版）；本仓库仅演示如何在微服务里接入官方 Starter，**不**改变 Spring Insight 作为通用工具的定位。

## 服务说明

| 模块 | 端口（本地） | 说明 |
|------|-------------|------|
| sca-gateway | 8080 | Spring Cloud Gateway；**Spring Insight 埋点**（WebFlux 过滤器），不含 MVC 控制台 |
| sca-order | 8081 | 下单 + Feign；**Docker 下 Spring Insight 控制台挂在本服务** |
| sca-product | 8082 | 商品价格 |
| sca-user | 8083 | 用户：Feign 调用 loyalty |
| sca-loyalty | 8084 | 积分 |
| Nacos | 见下 | 在本机单独用 Docker 启动，compose **不包含** Nacos |

**Nacos**

- 容器名：`nacos-standalone`，地址 `nacos-standalone:8848`（`application-docker.yml`）
- 与业务容器同一 Docker 网络（默认 **`my-network`**，见下文「Compose 网络说明」）
- 宿主端口示例：`38080:8080`、`38848:8848`、`39848:9848`
- IDE 使用 `127.0.0.1:38848`（`application.yml`）

**Spring Insight（本 demo 的接入方式）**

- 网关 **保留** `spring-insight-spring-boot-starter`，并对 **`insight-collector`**、**`spring-boot-starter-web`** 做 **Maven exclusion**（避免 WebFlux 与 MVC 混用）；Starter 中的 **`insight-collector-service`**（收集器业务层，与 demo 无关的通用模块）仍在，由 **WebFlux `WebFilter`** 采网关入口流量。
- **Insight 控制台（Docker）**：MVC 与静态资源仍在 **Servlet** 服务上，请访问 **<http://localhost:8081/>**（**sca-order**，compose 已映射 `8081:8081`）。

网关路由：`/order/**`、`/product/**`、`/user/**`、`/loyalty/**`。

## Compose 网络说明（`networks: [demo_net]` 是什么？）

`docker-compose.yml` 里 **`demo_net` 只是 Compose 文件中的逻辑名**，通过：

```yaml
networks:
  demo_net:
    name: ${DOCKER_NETWORK:-my-network}
    external: true
```

指向**已存在的** Docker 网络（默认 **`my-network`**），与 `docker run --network my-network` 启动的 **Nacos 在同一张网**，容器之间可用 **`nacos-standalone`** 解析。

若写成 `networks: [demo_net]`，**不是**另建一张与 `my-network` 隔离的网；**就是**加入 `name` 所指的那张网。

## 本地运行（IDE）

1. `docker network create my-network`（若尚无）
2. 启动 **Nacos**（`--network my-network`，容器名 `nacos-standalone`）
3. **`spring-insight` 父工程** `mvn clean install -DskipTests`
4. 本目录启动各 `*Application`

## Docker Compose 一键启动

1. **`.\compose-up.ps1`**（Windows）或 **`./compose-up.sh`**（Linux/macOS）：**每次**执行都会 **`mvnw clean package -DskipTests`**、**`docker compose up -d --build`**，容器在后台运行，脚本结束后**不会**一直刷容器日志。
2. 复制 **`.env.example`** 为 **`.env`** 可配置 **`DOCKER_NETWORK`**、**`NACOS_USERNAME`** / **`NACOS_PASSWORD`**

### 与脚本等价的命令行（自行执行）

在 **`spring-insight-sca-demo`** 目录下（已配置好 `mvnw` 与 `docker-compose.yml`）：

```bash
# 1）将 Spring Insight 安装到本机 Maven 仓库（若你改的是与本仓库同级的 spring-insight 源码，需要先 install）
# cd ../spring-insight && ./mvnw.cmd -B -ntp clean install -DskipTests   # Windows
# cd ../spring-insight && ./mvnw -B -ntp clean install -DskipTests        # Unix

# 2）打包 demo 全部模块
./mvnw.cmd -B -ntp clean package -DskipTests    # Windows
# ./mvnw -B -ntp clean package -DskipTests      # Linux/macOS

# 3）确保与 Nacos 共用网络（默认名与 .env 中 DOCKER_NETWORK 一致，例如 my-network）
docker network create my-network || true   # Linux/macOS：已存在会失败，可忽略

# 4）构建镜像并后台启动
docker compose up -d --build
```

PowerShell 创建网络（不存在则创建）：

```powershell
docker network inspect my-network 2>$null | Out-Null; if (-not $?) { docker network create my-network }
```

查看日志：`docker compose logs -f` 或 `docker compose logs -f sca-gateway`。

### 访问

- API 网关：<http://localhost:8080/>
- **Insight 控制台（Docker）**：<http://localhost:8081/>
- Nacos 控制台：按你本机端口映射（如 <http://localhost:38848/nacos>）

### Nacos 报 401 / `User not found`

说明客户端账号与 Nacos 服务端不一致。请保证：

1. Nacos 控制台能使用 **`nacos` / `nacos`** 登录；或  
2. 在 **`.env`** 中设置 **`NACOS_USERNAME`**、**`NACOS_PASSWORD`**（与控制台一致），并重新 `docker compose up`。

修改 **`spring-insight` 源码**后需先在其目录执行 **`mvn install`**，再在 demo 目录执行 **`compose-up`** 或 **`mvnw clean package`** 后 **`docker compose up -d --build`**。

## Spring Insight 数据存储

Trace/Span 在**集成 Insight 控制台的 JVM** 内存中；Docker 默认在 **sca-order** 上看控制台。
