package io.github.iweidujiang.scaorder.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestTemplate;

/**
 * Demo 用 HTTP 客户端：走 RestTemplateBuilder / RestClient.Builder，以便 Insight Customizer 注入 CLIENT Span。
 * <p>
 * 手写 {@code new RestTemplate()} / {@code RestClient.create()} 不会埋点。
 * </p>
 *
 * @since 2026-09-18
 * @author 公众号：苏渡苇 GitHub：https://github.com/iweidujiang
 */
@Configuration
public class DemoHttpClientConfiguration {

    /**
     * LoadBalanced RestTemplate：URI host 为服务名（如 {@code sca-product}）。
     *
     * @param builder Boot 管理的 Builder（已挂 Insight 拦截器）
     * @return RestTemplate
     */
    @Bean
    @LoadBalanced
    public RestTemplate loadBalancedRestTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }

    /**
     * RestClient：同样走 Boot Customizer；直连 URL 时 remoteService 为 host。
     *
     * @param builder Boot 管理的 Builder（已挂 Insight 拦截器）
     * @return RestClient
     */
    @Bean
    public RestClient restClient(RestClient.Builder builder) {
        return builder.build();
    }
}
