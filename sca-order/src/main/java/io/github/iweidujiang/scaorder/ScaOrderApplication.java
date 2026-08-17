package io.github.iweidujiang.scaorder;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * 订单服务。Insight 由 spring-insight-agent-starter 自动装配，无需 {@code @EnableSpringInsight}。
 */
@EnableDiscoveryClient
@EnableFeignClients
@SpringBootApplication
public class ScaOrderApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaOrderApplication.class, args);
    }
}
