package io.github.iweidujiang.scaorder.controller;

import io.github.iweidujiang.scaorder.feign.UserFeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * JDBC 造数入口（根路径），经网关可直接打 {@code /call-jdbc-*}。
 * <p>
 * 内部仍走 Feign → sca-user H2；等价于 {@code /order/jdbc-*}。
 * </p>
 *
 * @author 苏渡苇
 * @since 2026-11-18
 */
@RestController
public class CallJdbcController {

    private final UserFeignClient userFeignClient;

    /**
     * @param userFeignClient 用户服务 Feign
     */
    public CallJdbcController(UserFeignClient userFeignClient) {
        this.userFeignClient = userFeignClient;
    }

    /**
     * 跨服务 JDBC 慢查询：order → user H2。
     *
     * @param ms sleep 毫秒，默认 600
     * @return 包装后的 user 响应
     */
    @GetMapping("/call-jdbc-slow")
    public String callJdbcSlow(@RequestParam(value = "ms", defaultValue = "600") long ms) {
        return "order-call-jdbc-slow: " + userFeignClient.jdbcSlow(ms);
    }

    /**
     * 跨服务 JDBC 错误造数。
     *
     * @return 包装后的 user 响应
     */
    @GetMapping("/call-jdbc-error")
    public String callJdbcError() {
        return "order-call-jdbc-error: " + userFeignClient.jdbcError();
    }

    /**
     * 跨服务快查询；默认阈值下 user 侧不应出现 JDBC Span。
     *
     * @return 包装后的 user 响应
     */
    @GetMapping("/call-jdbc-fast")
    public String callJdbcFast() {
        return "order-call-jdbc-fast: " + userFeignClient.jdbcFast();
    }
}
