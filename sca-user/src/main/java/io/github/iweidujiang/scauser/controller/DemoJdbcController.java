package io.github.iweidujiang.scauser.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * JDBC 追踪造数（H2）：经网关 {@code /user/jdbc/**} 或直连 {@code :18083}。
 * <p>
 * 默认慢阈值 500ms：fast 不上报 JDBC Span；slow / error 应上报。
 * </p>
 *
 * @since 2026-10-12
 * @author 公众号：苏渡苇 GitHub：https://github.com/iweidujiang
 */
@RestController
@RequestMapping("/user/jdbc")
public class DemoJdbcController {

    private final JdbcTemplate jdbcTemplate;

    public DemoJdbcController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * 快 SELECT：默认阈值下不应出现 JDBC CLIENT Span。
     */
    @GetMapping("/fast")
    public Map<String, Object> fast() {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList("SELECT id, name, stock FROM demo_item ORDER BY id");
        Map<String, Object> body = new HashMap<>();
        body.put("scenario", "fast");
        body.put("rows", rows);
        body.put("hint", "默认 jdbc-slow-threshold-ms=500 时成功快查询不上报 JDBC Span");
        return body;
    }

    /**
     * 慢调用：H2 {@code CALL SLEEP_MS} 计入 JDBC 耗时，应上报且带 {@code db.slow=true}。
     *
     * @param ms sleep 毫秒，默认 600
     */
    @GetMapping("/slow")
    public Map<String, Object> slow(@RequestParam(value = "ms", defaultValue = "600") long ms) {
        long wait = Math.max(1L, Math.min(ms, 5000L));
        jdbcTemplate.execute("CALL SLEEP_MS(" + wait + ")");
        Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM demo_item", Integer.class);
        Map<String, Object> body = new HashMap<>();
        body.put("scenario", "slow");
        body.put("sleptMs", wait);
        body.put("itemCount", count);
        body.put("hint", "期望瀑布含 CLIENT/JDBC，operationName=DB EXECUTE（或 CALL），tag db.slow=true");
        return body;
    }

    /**
     * 错误 SQL：应始终上报 JDBC Span（errorCode=SQL_ERROR）。
     */
    @GetMapping("/error")
    public Map<String, Object> error() {
        try {
            jdbcTemplate.queryForList("SELECT * FROM demo_item_missing");
            Map<String, Object> unexpected = new HashMap<>();
            unexpected.put("ok", true);
            return unexpected;
        } catch (Exception e) {
            Map<String, Object> body = new HashMap<>();
            body.put("scenario", "error");
            body.put("exception", e.getClass().getSimpleName());
            body.put("message", e.getMessage());
            body.put("hint", "期望 JDBC CLIENT Span status=ERROR / errorCode=SQL_ERROR");
            return body;
        }
    }

    /**
     * 写路径：快 INSERT（默认阈值下不上报；阈值改 0 可见）。
     */
    @GetMapping("/write")
    public Map<String, Object> write() {
        long id = System.currentTimeMillis() % 1_000_000L;
        jdbcTemplate.update("INSERT INTO demo_item (id, name, stock) VALUES (?, ?, ?)",
                id, "widget-" + id, 1);
        Map<String, Object> body = new HashMap<>();
        body.put("scenario", "write");
        body.put("insertedId", id);
        return body;
    }
}
