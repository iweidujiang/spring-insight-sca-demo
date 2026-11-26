package io.github.iweidujiang.scaorder.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * 调用用户服务（sca-user），路径与 {@code UserController} 一致。
 */
@FeignClient("sca-user")
public interface UserFeignClient {

    @GetMapping("/user/score/{id}")
    Integer getScore(@PathVariable("id") Long id);

    @GetMapping("/user/addScore")
    Integer addScore(@RequestParam("id") Long id,
                     @RequestParam("lastScore") Integer lastScore,
                     @RequestParam("addScore") Integer addScore);

    /** JDBC 慢查询造数（sca-user H2） */
    @GetMapping("/user/jdbc/slow")
    String jdbcSlow(@RequestParam(value = "ms", defaultValue = "600") long ms);

    /** JDBC 错误造数 */
    @GetMapping("/user/jdbc/error")
    String jdbcError();

    /** JDBC 快查询造数 */
    @GetMapping("/user/jdbc/fast")
    String jdbcFast();

    /** Redis 多命令造数（sca-user） */
    @GetMapping("/user/redis/mix")
    String redisMix(@RequestParam(value = "key", defaultValue = "mix") String key);

    /** Redis GET 造数 */
    @GetMapping("/user/redis/get")
    String redisGet(@RequestParam(value = "key", defaultValue = "item") String key);

    /** Redis SET 造数 */
    @GetMapping("/user/redis/set")
    String redisSet(@RequestParam(value = "key", defaultValue = "item") String key,
                    @RequestParam(value = "value", defaultValue = "demo") String value);

    /** Redis HGET 造数 */
    @GetMapping("/user/redis/hget")
    String redisHget(@RequestParam(value = "key", defaultValue = "cart") String key);

    /** Redis 错误造数（WRONGTYPE） */
    @GetMapping("/user/redis/error")
    String redisError(@RequestParam(value = "key", defaultValue = "wrongtype") String key);
}
