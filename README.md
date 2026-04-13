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
| Nacos | 见下 | 注册中心；与 Docker 映射对齐 |

**Nacos（与 `docker-compose` / 本地 Docker 习惯一致）**

- 容器名：`nacos-standalone`
- 宿主端口映射：`38080:8080`、`38848:8848`、`39848:9848`（容器内仍为 8848 / 9848 / 8080）
- 业务进程跑在**宿主机（IDE）**时，默认使用 `127.0.0.1:38848` 连接 Nacos（见各模块 `application.yml`）
- 控制台示例：<http://localhost:38848/nacos>（账号密码默认 `nacos` / `nacos`）

本 demo **当前未使用 MySQL、Redis**；若你本地用 Docker 起了库，可在后续接入时在配置中指向对应宿主映射端口。

网关路由：`/order/**`、`/product/**`、`/user/**`、`/loyalty/**`。

## 本地运行（IDE）

1. 用 Docker 启动 **Nacos**（单机），并保持上述端口映射；与 `SPRING_PROFILES_ACTIVE` 默认配置一致时，应用会连 `127.0.0.1:38848`。
2. 若 `spring-insight-spring-boot-starter` 尚未从 **Maven Central** 解析到（例如仍为仅本地开发的 `0.1.0-SNAPSHOT`），在 **`spring-insight` 父工程目录**执行 `mvn clean install -DskipTests`（多模块一次安装到本机 `~/.m2`，无需逐个子模块安装）。说明见 [`spring-insight/README.md`](../spring-insight/README.md#0-安装到本机-maven-仓库)。
3. 按依赖顺序启动各 `*Application`（或先起 product、loyalty，再起 user、order，最后 gateway）。

手动造流量示例：

```http
GET http://localhost:8080/order/create?userId=1&productId=1
```

然后在浏览器打开 **http://localhost:8080/** 查看 Insight 控制台（链路、拓扑等）。

## Docker Compose 一键启动（推荐）

本目录下的 Docker 配置用于**简化本地联调**：在宿主已把 Spring Insight **安装到本机 Maven 仓库**的前提下，**一条命令**拉起 Nacos、全部业务服务以及周期性压测容器（`traffic`）。

### 前置条件

1. 在 **`spring-insight` 父工程**执行（只需一次，或你改了 insight 代码后重跑）：

   ```bash
   mvn clean install -DskipTests
   ```

2. 已安装 **Docker** 与 **Docker Compose v2.17+**（需支持 `additional_contexts`），并开启 **BuildKit**（脚本里会设 `DOCKER_BUILDKIT=1`）。

### 一条命令启动

在 **`spring-insight-sca-demo` 目录**执行：

- **Windows（PowerShell）**

  ```powershell
  .\compose-up.ps1
  ```

- **macOS / Linux**

  ```bash
  chmod +x compose-up.sh   # 首次可选
  ./compose-up.sh
  ```

脚本会把 **`LOCAL_M2_REPOSITORY`** 默认指到当前用户的 **`~/.m2/repository`**（Windows 为 `%USERPROFILE%\.m2\repository`），再执行 `docker compose up --build`。

### 直接使用 docker compose

若已自行设置环境变量，也可：

```powershell
$env:LOCAL_M2_REPOSITORY = "$env:USERPROFILE\.m2\repository"
$env:DOCKER_BUILDKIT = "1"
docker compose up --build
```

或复制 **`.env.example`** 为 **`.env`** 并填写 `LOCAL_M2_REPOSITORY`（Compose 会自动读取）。

### 构建较慢、日志很少？

1. Nacos 用现成镜像会**立刻**打日志；其余 5 个服务要先 **构建镜像**（镜像内 Maven 编译，首次常需**数分钟**），这段时间除 Nacos 外几乎无新日志属正常。
2. 想看编译过程可另开终端：`$env:DOCKER_BUILDKIT=1; $env:BUILDKIT_PROGRESS="plain"; docker compose build`
3. 内存紧张时可限制并行：`$env:COMPOSE_PARALLEL_LIMIT=1`（PowerShell）再 `docker compose build`。

### 访问地址

- Nacos：<http://localhost:38848/nacos>（默认 `nacos` / `nacos`）；若镜像映射了 `38080:8080`，也可按你的镜像说明访问对应端口
- 网关（含 Insight UI）：<http://localhost:8080/>

若本机**已单独占用** `38848` / `39848` / `38080`，请先停掉冲突容器再 `compose up`，或改 compose 端口并同步修改各模块 `application.yml` 中的 `server-addr`。
- **`traffic`** 服务约每 10 秒请求一次下单接口以产生 Span；不需要可在 `docker-compose.yml` 中注释掉该服务。

首次启动请待 Nacos 与各实例注册完成（约 30～60 秒）再访问控制台。

## Spring Insight 数据存储

当前 Starter 将 Trace/Span 保存在 **集成 Insight 控制台的那个 JVM 进程内存**中（例如网关）。多实例时，每个实例各自一份数据；**换 H2 等数据库需在本仓库（spring-insight）中实现持久化层**，本 demo 仅负责产生调用流量。
