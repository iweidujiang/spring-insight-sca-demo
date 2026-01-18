package io.github.iweidujiang.gateway;

import io.github.iweidujiang.springinsight.annotation.EnableSpringInsight;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableSpringInsight
@EnableDiscoveryClient
@SpringBootApplication
public class ScaGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaGatewayApplication.class, args);
    }

}
