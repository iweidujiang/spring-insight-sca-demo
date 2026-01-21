package io.github.iweidujiang.scaloyalty;

import io.github.iweidujiang.springinsight.agent.autoconfigure.EnableSpringInsight;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableSpringInsight
@EnableDiscoveryClient
@SpringBootApplication
public class ScaLoyaltyApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaLoyaltyApplication.class, args);
    }

}
