package io.github.iweidujiang.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * API 网关（WebFlux）。Insight Agent 自动装配
 */
@EnableDiscoveryClient
@SpringBootApplication
public class ScaGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaGatewayApplication.class, args);
    }
}
