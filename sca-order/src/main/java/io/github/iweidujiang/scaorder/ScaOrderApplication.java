package io.github.iweidujiang.scaorder;

import io.github.iweidujiang.springinsight.annotation.EnableSpringInsight;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableSpringInsight
@EnableDiscoveryClient
@EnableFeignClients
@SpringBootApplication
public class ScaOrderApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaOrderApplication.class, args);
    }

}
