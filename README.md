# spring-insight-sca-demo

Spring Cloud Alibaba（Nacos）多服务演示工程，用于压测 **Spring Insight** 的链路、拓扑与控制台。

## 服务说明

| 模块 | 端口（本地） | 说明 |
|------|-------------|------|
| sca-gateway | 8080 | Spring Cloud Gateway + **Spring Insight UI** |
| sca-order | 8081 | 下单：Feign 调用 user、product |
| sca-product | 8082 | 商品价格 |
| sca-user | 8083 | 用户：Feign 调用 loyalty |
| sca-loyalty | 8084 | 积分 |
| Nacos | 8848 | 注册中心 |

网关路由：`/order/**`、`/product/**`、`/user/**`、`/loyalty/**`。

## 本地运行（IDE）

1. 启动 **Nacos**（单机，默认 `localhost:8848`，控制台 `nacos/nacos`）。
2. 在 **spring-insight** 仓库根目录执行：`mvn install -DskipTests`（将 `spring-insight-spring-boot-starter` 安装到本地 Maven 仓库）。
3. 按依赖顺序启动各 `*Application`（或先起 product、loyalty，再起 user、order，最后 gateway）。

手动造流量示例：

```http
GET http://localhost:8080/order/create?userId=1&productId=1
```

然后在浏览器打开 **http://localhost:8080/** 查看 Insight 控制台（链路、拓扑等）。

## Docker Compose 一键启动

目录需为：

```text
<父目录>/
  spring-insight/           ← 本控制台工程源码
  spring-insight-sca-demo/  ← 本仓库
```

在 **`spring-insight-sca-demo` 目录**执行（构建上下文为父目录，镜像内会先 `mvn install` spring-insight，**无需**先在宿主机 install）：

```bash
docker compose up --build
```

父目录下可放置 `.dockerignore`（已提供示例 `../.dockerignore`）以减小构建上下文。

- Nacos：<http://localhost:8848/nacos>（默认账号密码均为 `nacos`）
- 网关（含 Insight UI）：<http://localhost:8080/>
- Compose 中的 **`traffic`** 服务会每 10 秒请求一次 `GET /order/create?userId=1&productId=1`，便于自动产生 Span；若不需要可注释掉 `docker-compose.yml` 里的 `traffic` 服务。

**说明：** 首次启动请等待 Nacos 与各实例注册完成（约 30～60 秒）再访问控制台。

## Spring Insight 数据存储

当前 Starter 将 Trace/Span 保存在 **集成 Insight 控制台的那个 JVM 进程内存**中（例如网关）。多实例时，每个实例各自一份数据；**换 H2 等数据库需在本仓库（spring-insight）中实现持久化层**，本 demo 仅负责产生调用流量。
