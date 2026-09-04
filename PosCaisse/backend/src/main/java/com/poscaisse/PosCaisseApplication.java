package com.poscaisse;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class PosCaisseApplication {
    public static void main(String[] args) {
        SpringApplication.run(PosCaisseApplication.class, args);
    }
}
