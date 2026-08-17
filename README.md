# spring-insight-sca-demo

基于 Spring Cloud Alibaba（Nacos）的微服务演示，用于验证 **Spring Insight** 的「业务 Agent + 独立监测中心」形态。

## 架构

```text
sca-gateway / order / product / user / loyalty
        │  spring-insight-agent-starter
        │  spring.insight.server-url → insight-server
        ▼
insight-server:9966   ← 唯一控制台与 Span 存储
```

- 各业务服务**只埋点上报**，不再内嵌 UI / Collector。
- Gateway（WebFlux）**无需** exclusion `starter-web`。
- 两仓须同级：`spring-insight` 与 `spring-insight-sca-demo`（Docker 构建 context 为 `..`）。

## 一键启动（Docker）

```bash
cd spring-insight-sca-demo
docker compose up -d --build
```

停止：

```bash
docker compose down
```

可选持续造数：

```bash
docker compose --profile traffic up -d
```

## 访问地址

| 用途 | URL |
|------|-----|
| **Insight 控制台** | http://localhost:9966/ |
| 业务网关 | http://localhost:8080/ |
| 造数 | `curl "http://localhost:8080/order/create?userId=1&productId=1"` |
| Nacos | http://localhost:38848/nacos （nacos/nacos） |

验收 API 示例：

```bash
curl -sS "http://localhost:9966/api/v1/health"
curl -sS "http://localhost:9966/api/v1/ui/services"
curl -sS "http://localhost:9966/api/v1/ui/dependencies"
```

造数后等约 5 秒（Agent 异步批量上报），再刷新控制台。

## 端口

| 服务 | 本机端口 | 容器端口 |
|------|----------|----------|
| insight-server | **9966** | 9966 |
| sca-gateway | 8080 | 18080 |
| sca-order | 8081 | 18081 |
| sca-nacos | 38080 / 38848 / 39848 | 8080 / 8848 / 9848 |

`product` / `user` / `loyalty` 不暴露宿主端口。

## 本机 IDE 启动（非 Docker）

1. JDK 21；在 `spring-insight` 执行 `mvn clean install -DskipTests`
2. `docker compose up -d insight-server sca-nacos`（或本机起 server jar + Nacos）
3. 依次启动：loyalty → product → user → order → gateway  
   （各模块已配置 `spring.insight.server-url: http://localhost:9966`）
4. 造数：`curl "http://localhost:18080/order/create?userId=1&productId=1"`
5. 打开 http://localhost:9966/

业务依赖坐标：

```xml
<dependency>
  <groupId>io.github.iweidujiang</groupId>
  <artifactId>spring-insight-agent-starter</artifactId>
</dependency>
```

无需 `@EnableSpringInsight`；`serviceName` 默认取 `spring.application.name`。

## 说明

- Span 存在 **insight-server 内存**，重启 Server 后历史清空。
- 修改 `spring-insight` 源码后，compose `--build` 会在镜像内重新编译 Insight 与 Demo。
