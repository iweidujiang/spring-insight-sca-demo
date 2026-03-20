package io.github.iweidujiang.scauser;

import io.github.iweidujiang.springinsight.agent.autoconfigure.EnableSpringInsight;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@EnableSpringInsight
@EnableDiscoveryClient
@EnableFeignClients
@SpringBootApplication
public class ScaUserApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaUserApplication.class, args);
    }

}
