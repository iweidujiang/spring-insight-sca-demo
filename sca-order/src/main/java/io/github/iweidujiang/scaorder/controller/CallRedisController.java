package io.github.iweidujiang.scaorder.controller;

import io.github.iweidujiang.scaorder.feign.UserFeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Redis 造数入口（根路径），经网关可直接打 {@code /call-redis-*}。
 * <p>
 * 内部走 Feign → sca-user Redis；等价于 {@code /order/redis-*}。
 * </p>
 *
 * @author 苏渡苇
 * @since 2026-11-26
 */
@RestController
public class CallRedisController {

    private final UserFeignClient userFeignClient;

    /**
     * @param userFeignClient 用户服务 Feign
     */
    public CallRedisController(UserFeignClient userFeignClient) {
        this.userFeignClient = userFeignClient;
    }

    /**
     * 跨服务多命令造数：order → user Redis（SET/GET/HSET/HGET/INCR/DEL）。
     *
     * @param key key 后缀
     * @return 包装后的 user 响应
     */
    @GetMapping("/call-redis-mix")
    public String callRedisMix(@RequestParam(value = "key", defaultValue = "mix") String key) {
        return "order-call-redis-mix: " + userFeignClient.redisMix(key);
    }

    /**
     * 跨服务 GET 造数。
     */
    @GetMapping("/call-redis-get")
    public String callRedisGet(@RequestParam(value = "key", defaultValue = "item") String key) {
        return "order-call-redis-get: " + userFeignClient.redisGet(key);
    }

    /**
     * 跨服务 SET 造数。
     */
    @GetMapping("/call-redis-set")
    public String callRedisSet(
            @RequestParam(value = "key", defaultValue = "item") String key,
            @RequestParam(value = "value", defaultValue = "demo") String value) {
        return "order-call-redis-set: " + userFeignClient.redisSet(key, value);
    }

    /**
     * 跨服务 HGET 造数。
     */
    @GetMapping("/call-redis-hget")
    public String callRedisHget(@RequestParam(value = "key", defaultValue = "cart") String key) {
        return "order-call-redis-hget: " + userFeignClient.redisHget(key);
    }

    /**
     * 跨服务 Redis 错误造数（WRONGTYPE）。
     */
    @GetMapping("/call-redis-error")
    public String callRedisError(@RequestParam(value = "key", defaultValue = "wrongtype") String key) {
        return "order-call-redis-error: " + userFeignClient.redisError(key);
    }
}
