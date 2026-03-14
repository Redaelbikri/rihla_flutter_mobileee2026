package com.rihla.hebergementservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients
public class HebergementServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(HebergementServiceApplication.class, args);
    }

}
