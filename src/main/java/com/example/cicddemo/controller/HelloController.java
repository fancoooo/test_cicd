package com.example.cicddemo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public Map<String, String> home() {
        return Map.of(
                "message", "Hello from Spring Boot CI/CD demo!",
                "version", "1.0.0"
        );
    }

    @GetMapping("/api/greet")
    public Map<String, String> greet() {
        return Map.of("greeting", greetingFor("DevOps"));
    }

    // Tach ra de co the unit test -> tao coverage cho SonarQube
    public String greetingFor(String name) {
        return "Xin chao, " + name + "!";
    }
}
