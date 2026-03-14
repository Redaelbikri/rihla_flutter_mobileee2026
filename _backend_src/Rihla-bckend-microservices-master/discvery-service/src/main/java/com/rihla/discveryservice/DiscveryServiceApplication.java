package com.rihla.discveryservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication
@EnableEurekaServer
public class DiscveryServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(DiscveryServiceApplication.class, args);
    }

}
