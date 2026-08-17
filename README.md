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
2. 已获取并安装 Spring Insight 到本机 Maven 仓库，例如：

```bash
# 在 Spring Insight 仓库目录（与本 Demo 无关的独立路径）
mvn clean install -DskipTests
```

3. 准备好 `insight-server` 可执行 jar（通常在 Insight 工程的 `insight-server/target/insight-server-*-SNAPSHOT.jar`）  
4. 复制环境变量模板并改成**你的本机路径**：

```bash
cd spring-insight-sca-demo
cp .env.example .env
# 编辑 .env：MAVEN_REPO、INSIGHT_SERVER_JAR
```

| 变量 | 含义 |
|------|------|
| `MAVEN_REPO` | Maven **localRepository** 目录（含 `io/github/iweidujiang/...`） |
| `INSIGHT_SERVER_JAR` | 已构建的 `insight-server` fat jar 路径 |

> Windows 路径建议用正斜杠，例如 `D:/Java/mvn_repo`。

## 一键启动（Docker）

在 **本工程根目录**（不要用上级目录当 context）：

```bash
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
| Nacos | http://localhost:38848/nacos （默认 nacos/nacos） |

```bash
curl -sS "http://localhost:9966/api/v1/health"
curl -sS "http://localhost:9966/api/v1/ui/services"
curl -sS "http://localhost:9966/api/v1/ui/dependencies"
```

造数后约等 5 秒（Agent 异步批量上报）再刷新控制台。

## 端口

| 服务 | 本机端口 | 说明 |
|------|----------|------|
| insight-server | 9966 | 挂载外部 jar 运行 |
| sca-gateway | 8080 | 业务入口 |
| sca-order | 8081 | 可直连 |
| sca-nacos | 38848 等 | 注册中心 |

## 本机 IDE 启动

1. 确保本机 Maven 已能解析 `spring-insight-agent-starter`  
2. 单独启动 Insight：`java -jar <insight-server.jar>`（端口 9966）  
3. 启动 Nacos（可用 `docker compose up -d sca-nacos`）  
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
