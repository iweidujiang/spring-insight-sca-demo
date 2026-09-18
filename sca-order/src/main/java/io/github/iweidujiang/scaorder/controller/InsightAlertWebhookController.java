package io.github.iweidujiang.scaorder.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.concurrent.atomic.AtomicLong;

/**
 *  Webhook ：接收 insight-server POST 的 JSON。
 * <p>
 * 配置 Server：{@code spring.insight.server.alert.webhook-url=http://host.docker.internal:{ORDER_PORT}/insight-alert/webhook}
 * （经网关则为 {@code http://host.docker.internal:{GATEWAY_PORT}/insight-alert/webhook}）。
 * </p>
 *
 * @since 2026-09-18
 * @author 公众号：苏渡苇 GitHub：https://github.com/iweidujiang
 */
@Slf4j
@RestController
@RequestMapping("/insight-alert")
public class InsightAlertWebhookController {

    private static final int MAX_RECENT = 50;

    private final AtomicLong receivedTotal = new AtomicLong();
    private final ConcurrentLinkedDeque<Map<String, Object>> recent = new ConcurrentLinkedDeque<>();

    /**
     * 接收告警 JSON（与钉钉群机器人类似：HTTP POST）。
     *
     * @param body 请求体；允许为空
     * @return 204
     */
    @PostMapping("/webhook")
    public ResponseEntity<Void> receive(@RequestBody(required = false) Map<String, Object> body) {
        long n = receivedTotal.incrementAndGet();
        log.info("[Demo告警Webhook] #{} 收到告警: {}", n, body);
        if (body != null) {
            recent.addFirst(Map.copyOf(body));
            while (recent.size() > MAX_RECENT) {
                recent.removeLast();
            }
        }
        return ResponseEntity.noContent().build();
    }

    /**
     * 查看最近收到的告警（便于浏览器/curl 核对，无需翻日志）。
     *
     * @return 计数与最近若干条
     */
    @GetMapping("/recent")
    public Map<String, Object> recent() {
        return Map.of(
                "service", "sca-order",
                "receivedTotal", receivedTotal.get(),
                "at", Instant.now().toString(),
                "recent", recent.toArray());
    }
}
