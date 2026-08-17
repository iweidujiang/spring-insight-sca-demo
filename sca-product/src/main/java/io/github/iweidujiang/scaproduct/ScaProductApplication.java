package io.github.iweidujiang.scaproduct;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableDiscoveryClient
@SpringBootApplication
public class ScaProductApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaProductApplication.class, args);
    }
}
