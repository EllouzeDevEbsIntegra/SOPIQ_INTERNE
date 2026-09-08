package com.poscaisse.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

/**
 * Sert l'application Vue compilée (classpath:/static ou ../frontend/dist) avec repli SPA sur index.html.
 * Si aucun build n'est présent (dist n'est pas versionné), une page d'explication est renvoyée
 * plutôt qu'un 404 JSON incompréhensible.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Value("${poscaisse.frontend-dist:../frontend/dist}") private String frontendDist;

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
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
                        // Aucun build : NoResourceFoundException -> page d'aide (GlobalExceptionHandler)
                        return cp.exists() ? cp : null;
                    }
                });
    }

}
