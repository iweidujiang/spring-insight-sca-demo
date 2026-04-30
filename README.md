# spring-insight-sca-demo

基于 Spring Cloud Alibaba（Nacos）的微服务演示工程，用于展示 Spring Insight 的链路追踪、拓扑与控制台能力。

## 本次 Docker 方案

- 每个微服务各自维护独立 `Dockerfile`：  
  `sca-gateway/Dockerfile`、`sca-order/Dockerfile`、`sca-user/Dockerfile`、`sca-product/Dockerfile`、`sca-loyalty/Dockerfile`
- `docker-compose.yml` 直接构建并启动完整环境（含 `sca-nacos`）
- 全部容器固定使用项目专属 Docker 网络 `sca-net`，与其他项目隔离
- 无需预先在宿主机执行 Maven 打包；直接一条命令启动

## 一键启动

在 `spring-insight-sca-demo` 目录执行：

```bash
docker compose up -d --build
```

停止并清理：

```bash
docker compose down
```

## 服务端口

| 服务 | 本机端口 | 容器端口 |
|------|----------|----------|
| sca-gateway | 8080 | 18080 |
| sca-order | 8081 | 18081 |
| sca-nacos | 38080 / 38848 / 39848 | 8080 / 8848 / 9848 |

`sca-product`、`sca-user`、`sca-loyalty` 不暴露宿主端口，通过网关与服务间调用访问。

## 常用访问地址

- 网关：<http://localhost:8080/>
- Insight 控制台（经网关）：<http://localhost:8080/spring-insight/>
- Insight 控制台（直连 order）：<http://localhost:8081/spring-insight/>
- Nacos 控制台：<http://localhost:38848/nacos>

## 网络隔离

- 本项目容器全部加入 `sca-net`
- Nacos 服务名固定为 `sca-nacos`，各微服务在 docker profile 下统一使用 `sca-nacos:8848`

## 可选持续流量

`traffic` 服务默认不启动。需要持续压测流量时：

```bash
docker compose --profile traffic up -d
```

## 业务路由

| 路由前缀 | 目标服务 |
|----------|----------|
| `/order/**` | sca-order |
| `/product/**` | sca-product |
| `/user/**` | sca-user |
| `/loyalty/**` | sca-loyalty |

## 说明

- Spring Insight 数据默认在 `sca-order` 内存中保存，容器重启后数据清空。
- 若你修改了 `spring-insight` 源码，本 compose 构建会在镜像里重新执行 `spring-insight` 与 demo 的 Maven 构建。
