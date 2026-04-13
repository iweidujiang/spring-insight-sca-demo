# spring-insight-sca-demo

Spring Cloud Alibaba（Nacos）多服务演示工程，用于本地压测 **Spring Insight** 的链路、拓扑与控制台。

## 服务说明

| 模块 | 端口（本地） | 说明                                                                |
|------|-------------|-------------------------------------------------------------------|
| sca-gateway | 8080 | Spring Cloud Gateway + **Spring Insight UI**                      |
| sca-order | 8081 | 下单：Feign 调用 user、product                                          |
| sca-product | 8082 | 商品价格                                                              |
| sca-user | 8083 | 用户：Feign 调用 loyalty                                               |
| sca-loyalty | 8084 | 积分                                                                |
| Nacos | 见下 | 注册中心（**我在本机测试环境单独用 Docker 启动了 Nacos**，本仓库的 compose **不包含** Nacos） |

**Nacos（本机 Docker，与业务配置对齐）**

- 容器名：`nacos-standalone`（`application-docker.yml` 中 `server-addr: nacos-standalone:8848`）
- 需与 SCA 各服务处于**同一 Docker 网络**（默认 **`my-network`**，可通过环境变量 `DOCKER_NETWORK` 覆盖）
- 宿主端口示例：`38080:8080`、`38848:8848`、`39848:9848`
- 业务进程跑在**宿主机（IDE）**时，使用 `127.0.0.1:38848`（见各模块 `application.yml`）
- 控制台示例：<http://localhost:38848/nacos>

本 demo **当前未使用 MySQL、Redis**；若你本地用 Docker 起了库，可在后续接入时在配置中指向对应宿主映射端口。

网关路由：`/order/**`、`/product/**`、`/user/**`、`/loyalty/**`。

## 本地运行（IDE）

1. 先创建 Docker 网络（若尚未创建）：`docker network create my-network`
2. 启动 **Nacos**（单机），**务必加入 `my-network`**，容器名 **`nacos-standalone`**，并保持与 `application.yml` 一致的宿主端口映射。示例（路径与镜像版本请按本机修改）：

   ```bash
   docker run --name nacos-standalone --network my-network -e MODE=standalone ^
     -e NACOS_AUTH_TOKEN="..." -e NACOS_AUTH_IDENTITY_KEY="serverIdentity" -e NACOS_AUTH_IDENTITY_VALUE="nacosSecurity" ^
     -v D:\docker_service_data\nacos\application.properties:/home/nacos/conf/application.properties ^
     -v D:\docker_service_data\nacos\logs:/home/nacos/logs ^
     -p 38080:8080 -p 38848:8848 -p 39848:9848 -d nacos/nacos-server:v3.1.1
   ```

3. 在 **`spring-insight` 父工程**执行 `mvn clean install -DskipTests`。说明见 [`spring-insight/README.md`](../spring-insight/README.md#0-安装到本机-maven-仓库)。
4. 按依赖顺序启动各 `*Application`（或先起 product、loyalty，再起 user、order，最后 gateway）。

手动造流量示例：

```http
GET http://localhost:8080/order/create?userId=1&productId=1
```

然后在浏览器打开 **http://localhost:8080/** 查看 Insight 控制台（链路、拓扑等）。

## Docker Compose 一键启动（仅 SCA 服务）

本目录的 **docker-compose 不启动 Nacos**。请先按上一节启动 **`nacos-standalone` 且已加入 `my-network`**，再在本目录一键拉起各业务容器与压测 `traffic`。

### 前置条件

1. **`spring-insight` 父工程**：`mvn clean install -DskipTests`（按需）。
2. **Docker** + **Compose v2.17+**（`additional_contexts`）+ **BuildKit**。
3. **网络**：默认使用外部网络 **`my-network`**（与 `compose-up` 脚本一致）。若该网络不存在，脚本会尝试 `docker network create my-network`；**请保证已与 Nacos 使用的网络同名**，否则请先把 Nacos 接到该网络，或设置环境变量 `DOCKER_NETWORK` 与 Nacos 实际所在网络一致。

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

脚本会：解析 **Maven 本地库路径**（环境变量 **`MAVEN_LOCAL_REPOSITORY`**，与 `settings.xml` 里 `<localRepository>` 一致；若未设置则兼容旧名 **`LOCAL_M2_REPOSITORY`**，再回退到默认 `~/.m2/repository`）、设置 `DOCKER_NETWORK=my-network`（若未设置），必要时创建 `my-network`，再执行 `docker compose up --build`。若你使用自定义仓库路径（例如 `D:\Java\mvn_repo`），请在 **`.env`** 或环境中设置 `MAVEN_LOCAL_REPOSITORY=D:/Java/mvn_repo`（建议正斜杠）。

### 直接使用 docker compose

```powershell
$env:MAVEN_LOCAL_REPOSITORY = "D:/Java/mvn_repo"   # 与 settings.xml 中 localRepository 一致时必填
$env:DOCKER_NETWORK = "my-network"
$env:DOCKER_BUILDKIT = "1"
docker compose up --build
```

也可复制 **`.env.example`** 为 **`.env`**，填写 **`MAVEN_LOCAL_REPOSITORY`**（例如 `D:/java/mvn_repo`）及按需 **`DOCKER_NETWORK`**。**`compose-up.ps1` 会先读取 `.env`** 再启动 Compose。若曾构建失败，修复 Dockerfile 后请执行 **`docker compose build --no-cache`** 以免沿用错误缓存层。

### 构建较慢、日志很少？

1. 首次构建时 Maven 会从网络**下载大量依赖**，可能持续**数分钟甚至更久**，属正常现象；旧版 Dockerfile 使用 `mvn -q` 会**完全不打印进度**，看起来像卡住——当前已改为输出下载日志。
2. **`compose-up.ps1` / `compose-up.sh`** 默认设置 **`BUILDKIT_PROGRESS=plain`**（完整构建日志）和 **`COMPOSE_PARALLEL_LIMIT=1`**（串行构建各服务镜像，避免五个 Maven 同时跑占满资源且难以排查）。若要并行加速可设：`$env:COMPOSE_PARALLEL_LIMIT=5`（PowerShell）。
3. 手动构建：`$env:DOCKER_BUILDKIT=1; $env:BUILDKIT_PROGRESS="plain"; docker compose build`

### 访问地址

- Nacos：由你本机映射决定（示例 <http://localhost:38848/nacos>）
- 网关（含 Insight UI）：<http://localhost:8080/>
- **`traffic`**：约每 10 秒请求一次下单接口；不需要可在 `docker-compose.yml` 中注释掉该服务。

首次启动请待 Nacos 已就绪、各实例注册完成后再访问控制台。

## Spring Insight 数据存储

当前 Starter 将 Trace/Span 保存在 **集成 Insight 控制台的那个 JVM 进程内存**中（例如网关）。多实例时，每个实例各自一份数据；**换 H2 等数据库需在本仓库（spring-insight）中实现持久化层**，本 demo 仅负责产生调用流量。
