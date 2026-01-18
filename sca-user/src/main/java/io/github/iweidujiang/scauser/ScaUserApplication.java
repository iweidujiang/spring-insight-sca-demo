package io.github.iweidujiang.scauser;

import io.github.iweidujiang.springinsight.annotation.EnableSpringInsight;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableSpringInsight
@EnableDiscoveryClient
@SpringBootApplication
public class ScaUserApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScaUserApplication.class, args);
    }

}
