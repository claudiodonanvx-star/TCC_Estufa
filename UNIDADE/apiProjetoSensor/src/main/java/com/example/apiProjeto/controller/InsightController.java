package com.example.apiProjeto.controller;

import java.util.Map;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.apiProjeto.service.InsightService;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/insights")
public class InsightController {

    private final InsightService insightService;

    public InsightController(InsightService insightService) {
        this.insightService = insightService;
    }

    @GetMapping
    public Map<String, Object> obterInsights(@RequestParam(defaultValue = "30") int limite) {
        return insightService.gerarInsights(limite);
    }
}