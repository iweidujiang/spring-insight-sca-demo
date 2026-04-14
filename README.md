# spring-insight-sca-demo

Spring Cloud Alibaba（Nacos）多服务演示工程，用于本地压测 **Spring Insight** 的链路、拓扑与控制台。

## 服务说明

| 模块 | 端口（本地） | 说明 |
|------|-------------|------|
| sca-gateway | 8080 | Spring Cloud Gateway（**WebFlux**，不嵌 Spring Insight UI） |
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

**Spring Insight**

- **Gateway 为 WebFlux**，与基于 Servlet MVC 的 Spring Insight Starter **不能同进程**，故 **网关模块已去掉 Insight 依赖**。
- **Insight 控制台（Docker）**：请访问 **<http://localhost:8081/>**（**sca-order**，compose 已映射 `8081:8081`）。
- 本地 IDE 仍可在任意已接入 Starter 的模块上看控制台（原习惯若用 8080，可本地只跑网关+order）。

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

1. 宿主机 **`mvnw clean package -DskipTests`**（`compose-up` 在缺 jar 时会自动执行）
2. **`.\compose-up.ps1`** 或 **`./compose-up.sh`**
3. 复制 **`.env.example`** 为 **`.env`** 可配置 **`DOCKER_NETWORK`**、**`NACOS_USERNAME`** / **`NACOS_PASSWORD`**

### 访问

- API 网关：<http://localhost:8080/>
- **Insight 控制台（Docker）**：<http://localhost:8081/>
- Nacos 控制台：按你本机端口映射（如 <http://localhost:38848/nacos>）

### Nacos 报 401 / `User not found`

说明客户端账号与 Nacos 服务端不一致。请保证：

1. Nacos 控制台能使用 **`nacos` / `nacos`** 登录；或  
2. 在 **`.env`** 中设置 **`NACOS_USERNAME`**、**`NACOS_PASSWORD`**（与控制台一致），并重新 `docker compose up`。

修改 `pom` 或配置后请重新 **`mvnw package`** 再打镜像。

## Spring Insight 数据存储

Trace/Span 在**集成 Insight 控制台的 JVM** 内存中；Docker 默认在 **sca-order** 上看控制台。
