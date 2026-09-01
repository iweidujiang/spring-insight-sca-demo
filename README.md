# spring-insight-sca-demo

独立的 Spring Cloud Alibaba（Nacos）微服务演示工程，通过 Maven 依赖使用开源监测工具 **[Spring Insight](https://github.com/iweidujiang/spring-insight)**。

本仓库**不包含** Spring Insight 源码，也不在 Docker 构建中编译 Insight；将其视为与业务无关的第三方组件。

## 架构

```text
本工程微服务（gateway / order / product / user / loyalty）
        │  依赖坐标：spring-insight-agent-starter（Maven）
        │  配置：spring.insight.server-url
        ▼
第三方进程 insight-server:9966   ← 控制台 + Span 存储（由 Spring Insight 提供）
```

## 前置条件

1. **JDK 21**、Docker Compose v2  
2. **本机已启动 Nacos**（本 Demo **不再**用 compose 拉起 Nacos）。推荐与下列一致，以便容器通过 Docker 网络访问：

```bash
docker network create my-network   # 若尚不存在
docker run --name nacos-standalone --network my-network \
  -e MODE=standalone \
  -e NACOS_AUTH_TOKEN="aEJxaDVFMjIxcTlyQjlvOHZFMVBMaEM2emtZb1hjVWZEVE4=" \
  -e NACOS_AUTH_IDENTITY_KEY="serverIdentity" \
  -e NACOS_AUTH_IDENTITY_VALUE="nacosSecurity" \
  -v D:\docker_service_data\nacos\application.properties:/home/nacos/conf/application.properties \
  -v D:\docker_service_data\nacos\logs:/home/nacos/logs \
  -p 38080:8080 -p 38848:8848 -p 39848:9848 \
  -d nacos/nacos-server:v3.1.1
```

3. 已安装 Spring Insight 到本机 Maven 仓库，例如：

```bash
# 在 Spring Insight 仓库目录
mvn clean install -DskipTests
```

4. 准备好 `insight-server` 可执行 jar，并配置 `.env`：

```bash
cd spring-insight-sca-demo
cp .env.example .env
# 编辑：MAVEN_REPO、INSIGHT_SERVER_JAR、DOCKER_NETWORK（默认 my-network）
```

| 变量 | 含义 |
|------|------|
| `MAVEN_REPO` | Maven **localRepository**（含 `io/github/iweidujiang/...`） |
| `INSIGHT_SERVER_JAR` | 已构建的 `insight-server` fat jar |
| `DOCKER_NETWORK` | 与 Nacos 相同的外部网络（默认 `my-network`） |
| `NACOS_SERVER_ADDR` | 容器内地址（默认 `nacos-standalone:8848`） |

> Windows 路径建议用正斜杠，例如 `D:/Java/mvn_repo`。

## 一键启动（Docker）

确认 Nacos 已在 `DOCKER_NETWORK` 上运行后，在本工程根目录：

```bash
docker compose up -d --build
```

停止（**不会**停掉外部 Nacos）：

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
| 外部 Nacos | http://localhost:38848/nacos （账号见 `.env` 的 `NACOS_USERNAME`/`NACOS_PASSWORD`） |

```bash
curl -sS "http://localhost:9966/api/v1/health"
curl -sS "http://localhost:9966/api/v1/ui/services"
curl -sS "http://localhost:9966/api/v1/ui/dependencies"
```

造数后约等 5 秒（Agent 异步批量上报）再刷新控制台。

## 端口

| 服务 | 本机端口 | 说明 |
|------|----------|------|
| insight-server | 9966 | 挂载外部 jar |
| sca-gateway | 8080 | 业务入口 |
| sca-order | 8081 | 可直连 |
| nacos-standalone（外部） | 38848 等 | 本机自行维护，不在本 compose 内 |

## 本机 IDE 启动

1. 确保本机 Maven 已能解析 `spring-insight-agent-starter`  
2. 单独启动 Insight：`java -jar <insight-server.jar>`（端口 9966）  
3. 确保本机 Nacos 已映射到 `127.0.0.1:38848`（各模块 `application.yml` 默认连此地址）  
4. 再启动本工程各模块：loyalty → product → user → order → gateway  
5. 造数：`curl "http://localhost:18080/order/create?userId=1&productId=1"`  
6. 打开 http://localhost:9966/

## 业务侧如何接入 Insight（本工程已配置）

```xml
<dependency>
  <groupId>io.github.iweidujiang</groupId>
  <artifactId>spring-insight-agent-starter</artifactId>
  <version>0.1.0-SNAPSHOT</version>
</dependency>
```

```yaml
spring:
  application:
    name: sca-order
  insight:
    server-url: http://localhost:9966   # Docker 内为 http://insight-server:9966
```

无需 `@EnableSpringInsight`。

## Docker 构建说明

- 构建 context 为本仓库根目录；通用脚本为 `Dockerfile.service`。  
- 通过 Compose `additional_contexts.m2repo` 注入本机 Maven 仓库，从而解析第三方 `spring-insight-agent-starter`。  
- `insight-server` 服务**不构建** Insight 源码，只挂载 `INSIGHT_SERVER_JAR`。

## 说明

- Span 保存在 insight-server **进程内存**，重启 Server 后历史清空。  
- 升级 Insight 时：在 Insight 仓库重新 `mvn install` / 重新打包 server jar，再重建本 Demo 镜像即可。
