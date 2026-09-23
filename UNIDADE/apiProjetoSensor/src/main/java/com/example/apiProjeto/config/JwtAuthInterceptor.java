package com.example.apiProjeto.config;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.example.apiProjeto.service.JwtService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthInterceptor implements HandlerInterceptor {

    private final JwtService jwtService;
    private final boolean enforce;

    public JwtAuthInterceptor(JwtService jwtService,
                              @Value("${app.jwt.enforce:false}") boolean enforce) {
        this.jwtService = jwtService;
        this.enforce = enforce;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws IOException {
        if (!enforce || request.getRequestURI().startsWith("/api/usuarios/")
                || request.getRequestURI().equals("/api/ping")
                || request.getRequestURI().equals("/api/health")
                || (request.getRequestURI().equals("/api/dados") && "POST".equalsIgnoreCase(request.getMethod()))) {
            return true;
        }

        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.startsWith("Bearer ")
                && jwtService.tokenValido(authorization.substring(7))) {
            return true;
        }

        response.sendError(HttpStatus.UNAUTHORIZED.value(), "Token JWT ausente ou inválido");
        return false;
    }
}