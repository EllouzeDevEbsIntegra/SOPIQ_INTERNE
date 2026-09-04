package com.poscaisse.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration @ConfigurationProperties(prefix = "poscaisse") @Getter @Setter
public class AppProperties {
    private String timezone = "Africa/Tunis";
    private boolean demoData = true;
    private String corsOrigins;
}
