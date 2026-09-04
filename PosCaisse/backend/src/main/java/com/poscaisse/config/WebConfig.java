package com.poscaisse.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

/** Serves the built Vue app (classpath:/static or ../frontend/dist) with SPA fallback to index.html. */
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @org.springframework.beans.factory.annotation.Value("${poscaisse.frontend-dist:../frontend/dist}")
    private String frontendDist;

    @Override
    public void addViewControllers(org.springframework.web.servlet.config.annotation.ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("forward:/index.html");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String dist = frontendDist.endsWith("/") ? frontendDist : frontendDist + "/";
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/", "file:" + dist)
                .resourceChain(true)
                .addResolver(new PathResourceResolver() {
                    @Override
                    protected Resource getResource(String path, Resource location) throws java.io.IOException {
                        Resource r = location.createRelative(path);
                        if (r.exists() && r.isReadable()) return r;
                        if (path.startsWith("api/") || path.startsWith("actuator")) return null;
                        Resource index = location.createRelative("index.html");
                        if (index.exists() && index.isReadable()) return index;
                        Resource cp = new ClassPathResource("/static/index.html");
                        return cp.exists() ? cp : null;
                    }
                });
    }
}
