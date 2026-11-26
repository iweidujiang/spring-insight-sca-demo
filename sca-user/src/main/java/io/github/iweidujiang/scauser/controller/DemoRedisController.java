package io.github.iweidujiang.scauser.controller;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Redis 追踪造数：经网关 {@code /user/redis/**}、{@code /call-redis-*} 或直连 {@code :18083}。
 * <p>
 * 需本机 / Compose 中有 Redis，且 {@code spring.insight.redis-tracing-enabled=true}。
 * 联调默认 {@code redis-slow-threshold-ms=0}，成功命令也会上报，便于缓存页「按命令」汇总。
 * </p>
 *
 * @author 苏渡苇
 * @since 2026-11-26
 */
@RestController
@RequestMapping("/user/redis")
public class DemoRedisController {

    private static final String KEY_PREFIX = "sca:demo:redis:";

    private final StringRedisTemplate stringRedisTemplate;

    /**
     * @param stringRedisTemplate Spring Data Redis（走 ConnectionFactory，可被 Insight 包装）
     */
    public DemoRedisController(StringRedisTemplate stringRedisTemplate) {
        this.stringRedisTemplate = stringRedisTemplate;
    }

    /**
     * 一次打出多种命令（SET / GET / HSET / HGET / INCR / DEL），供缓存页命令分布造数。
     *
     * @param key 业务 key 后缀，默认 mix
     * @return 各命令执行摘要
     */
    @GetMapping("/mix")
    public Map<String, Object> mix(@RequestParam(value = "key", defaultValue = "mix") String key) {
        String base = KEY_PREFIX + sanitize(key);
        String strKey = base + ":str";
        String hashKey = base + ":hash";
        String counterKey = base + ":cnt";

        List<String> commands = new ArrayList<>();
        stringRedisTemplate.opsForValue().set(strKey, "hello-" + System.currentTimeMillis(), 10, TimeUnit.MINUTES);
        commands.add("SET " + strKey);
        String got = stringRedisTemplate.opsForValue().get(strKey);
        commands.add("GET " + strKey);
        stringRedisTemplate.opsForHash().put(hashKey, "f1", "v1");
        commands.add("HSET " + hashKey);
        Object hget = stringRedisTemplate.opsForHash().get(hashKey, "f1");
        commands.add("HGET " + hashKey);
        Long incr = stringRedisTemplate.opsForValue().increment(counterKey);
        commands.add("INCR " + counterKey);
        Boolean deleted = stringRedisTemplate.delete(base + ":tmp-missing");
        commands.add("DEL " + base + ":tmp-missing");

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("scenario", "mix");
        body.put("commands", commands);
        body.put("getValue", got);
        body.put("hgetValue", hget);
        body.put("incrValue", incr);
        body.put("delExisted", deleted);
        body.put("hint", "期望 sca-user 上报多条 REDIS Span（SET/GET/HSET/HGET/INCR/DEL）；缓存页「按命令」可见分布");
        return body;
    }

    /**
     * 单次 GET（先确保 key 存在）。
     *
     * @param key key 后缀
     */
    @GetMapping("/get")
    public Map<String, Object> get(@RequestParam(value = "key", defaultValue = "item") String key) {
        String redisKey = KEY_PREFIX + sanitize(key);
        stringRedisTemplate.opsForValue().setIfAbsent(redisKey, "seed", 10, TimeUnit.MINUTES);
        String value = stringRedisTemplate.opsForValue().get(redisKey);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("scenario", "get");
        body.put("key", redisKey);
        body.put("value", value);
        body.put("hint", "期望 REDIS GET Span");
        return body;
    }

    /**
     * 单次 SET。
     *
     * @param key   key 后缀
     * @param value 写入值
     */
    @GetMapping("/set")
    public Map<String, Object> set(
            @RequestParam(value = "key", defaultValue = "item") String key,
            @RequestParam(value = "value", defaultValue = "demo") String value) {
        String redisKey = KEY_PREFIX + sanitize(key);
        stringRedisTemplate.opsForValue().set(redisKey, value, 10, TimeUnit.MINUTES);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("scenario", "set");
        body.put("key", redisKey);
        body.put("value", value);
        body.put("hint", "期望 REDIS SET Span");
        return body;
    }

    /**
     * Hash：HSET + HGET。
     *
     * @param key key 后缀
     */
    @GetMapping("/hget")
    public Map<String, Object> hget(@RequestParam(value = "key", defaultValue = "cart") String key) {
        String redisKey = KEY_PREFIX + sanitize(key) + ":hash";
        stringRedisTemplate.opsForHash().put(redisKey, "sku", "sku-1");
        Object field = stringRedisTemplate.opsForHash().get(redisKey, "sku");
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("scenario", "hget");
        body.put("key", redisKey);
        body.put("field", "sku");
        body.put("value", field);
        body.put("hint", "期望 REDIS HSET / HGET Span");
        return body;
    }

    /**
     * 错误造数：对 string key 做 HGET，触发 WRONGTYPE。
     *
     * @param key key 后缀
     */
    @GetMapping("/error")
    public Map<String, Object> error(@RequestParam(value = "key", defaultValue = "wrongtype") String key) {
        String redisKey = KEY_PREFIX + sanitize(key);
        stringRedisTemplate.opsForValue().set(redisKey, "plain-string", 10, TimeUnit.MINUTES);
        try {
            stringRedisTemplate.opsForHash().get(redisKey, "f");
            Map<String, Object> unexpected = new LinkedHashMap<>();
            unexpected.put("ok", true);
            unexpected.put("hint", "未触发 WRONGTYPE，请检查 Redis 客户端行为");
            return unexpected;
        } catch (Exception e) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("scenario", "error");
            body.put("key", redisKey);
            body.put("exception", e.getClass().getSimpleName());
            body.put("message", e.getMessage());
            body.put("hint", "期望 REDIS HGET Span 为 ERROR（WRONGTYPE）");
            return body;
        }
    }

    private static String sanitize(String key) {
        String raw = key == null ? "mix" : key.trim();
        if (raw.isEmpty()) {
            return "mix";
        }
        return raw.replaceAll("[^a-zA-Z0-9:_-]", "_");
    }
}
