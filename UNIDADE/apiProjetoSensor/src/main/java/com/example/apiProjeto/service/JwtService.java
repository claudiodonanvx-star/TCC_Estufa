package com.example.apiProjeto.service;

import java.nio.charset.StandardCharsets;
import java.util.Date;

import javax.crypto.SecretKey;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

@Service
public class JwtService {

    private final SecretKey key;
    private final long expirationMs;

    public JwtService(@Value("${app.jwt.secret:estufa-smart-chave-local-2026-com-mais-de-32-caracteres}") String secret,
                      @Value("${app.jwt.expiration-ms:43200000}") long expirationMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    public String gerarToken(String subject) {
        Date agora = new Date();
        return Jwts.builder()
                .setSubject(subject)
                .setIssuedAt(agora)
                .setExpiration(new Date(agora.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public boolean tokenValido(String token) {
        try {
            Claims claims = Jwts.parserBuilder().setSigningKey(key).build()
                    .parseClaimsJws(token).getBody();
            return claims.getSubject() != null && claims.getExpiration().after(new Date());
        } catch (Exception erro) {
            return false;
        }
    }
}