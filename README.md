# spring-insight-sca-demo

Spring Cloud Alibaba（Nacos）多服务演示工程，用于本地压测 **Spring Insight** 的链路、拓扑与控制台。

## 服务说明

| 模块 | 端口（本地） | 说明 |
|------|-------------|------|
| sca-gateway | 8080 | Spring Cloud Gateway + **Spring Insight UI** |
| sca-order | 8081 | 下单：Feign 调用 user、product |
| sca-product | 8082 | 商品价格 |
| sca-user | 8083 | 用户：Feign 调用 loyalty |
| sca-loyalty | 8084 | 积分 |
| Nacos | 见下 | 注册中心（**在本机单独用 Docker 启动**，本 compose **不包含** Nacos） |

**Nacos（本机 Docker）**

- 容器名：`nacos-standalone`（`application-docker.yml`：`nacos-standalone:8848`）
- 与 SCA 各服务同一 Docker 网络（默认 **`my-network`**，环境变量 **`DOCKER_NETWORK`** 可覆盖）
- 宿主端口示例：`38080:8080`、`38848:8848`、`39848:9848`
- IDE 直连时使用 `127.0.0.1:38848`（各模块 `application.yml`）
- 控制台示例：<http://localhost:38848/nacos>

本 demo **当前未使用 MySQL、Redis**。

网关路由：`/order/**`、`/product/**`、`/user/**`、`/loyalty/**`。

## 本地运行（IDE）

1. 创建网络（若尚无）：`docker network create my-network`
2. 启动 **Nacos**（加入 `my-network`，容器名 `nacos-standalone`），端口按你本机习惯映射。
3. 在 **`spring-insight` 父工程**执行 `mvn clean install -DskipTests`（Starter 进本地库）。说明见 [`spring-insight/README.md`](../spring-insight/README.md#0-安装到本机-maven-仓库)。
4. 在本目录用 IDE 启动各服务（或先 product、loyalty → user → order → gateway）。

## Docker Compose 一键启动（推荐）

**设计说明**：不在 Docker 镜像里跑 Maven（避免每次构建数分钟、日志像卡住）。改为：

1. **在本机**用 **`mvnw`** 打 fat jar（走你的 `settings.xml` / 自定义本地库如 `D:/java/mvn_repo`）。
2. **Docker 只负责**把各模块 `target/*.jar` 拷进 JRE 镜像并运行，**镜像构建通常几十秒内完成**。
3. `compose-up` 若发现缺少 jar，会先自动执行一次 `mvnw clean package -DskipTests`。

### 前置条件

1. **`spring-insight` 已 `mvn install`**（本机库里有 `spring-insight-spring-boot-starter`）。
2. **Nacos** 已启动并接入 **`my-network`**（与下文 `DOCKER_NETWORK` 一致）。
3. 已安装 **Docker**、**Docker Compose**。

### 一条命令

在 **`spring-insight-sca-demo` 目录**：

```powershell
.\compose-up.ps1
```

```bash
./compose-up.sh
```

可选：复制 **`.env.example`** 为 **`.env`**，只配 **`DOCKER_NETWORK`**（默认 `my-network`）。**不再需要** `MAVEN_LOCAL_REPOSITORY`——Maven 只在宿主机执行。

### 手动步骤（等价于脚本）

```powershell
.\mvnw.cmd -B -ntp clean package -DskipTests   # 或已打过包可跳过
docker compose up --build
```

### 访问

- Nacos：按你本机映射（如 <http://localhost:38848/nacos>）
- 网关（Insight UI）：<http://localhost:8080/>

## Spring Insight 数据存储

Trace/Span 在**集成 Insight 控制台的 JVM** 内存中（多为网关）；多实例各管各的。
