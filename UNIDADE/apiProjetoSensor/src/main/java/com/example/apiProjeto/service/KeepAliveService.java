package com.example.apiProjeto.service;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDateTime;

/**
 * Serviço para manter a API ativa no Render.
 * Faz um ping periódico em si mesma para evitar hibernação.
 */
@Service
public class KeepAliveService {

    private static final String KEEP_ALIVE_URL = System.getenv("KEEP_ALIVE_URL");
    private static final HttpClient httpClient = HttpClient.newHttpClient();

    /**
     * Executa a cada 20 minutos para manter a API acordada.
     * Se KEEP_ALIVE_URL não estiver configurada, apenas loga.
     */
    @Scheduled(fixedRate = 20 * 60 * 1000) // 20 minutos
    public void keepApiAlive() {
        if (KEEP_ALIVE_URL == null || KEEP_ALIVE_URL.isEmpty()) {
            System.out.println("[KeepAlive] Variável KEEP_ALIVE_URL não configurada. Pulando ping externo.");
            return;
        }

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(KEEP_ALIVE_URL + "/api/health"))
                    .GET()
                    .build();

            httpClient.sendAsync(request, HttpResponse.BodyHandlers.discarding())
                    .thenAccept(response -> {
                        if (response.statusCode() == 200) {
                            System.out.println("[KeepAlive] " + LocalDateTime.now() + " - API respondendo com sucesso!");
                        } else {
                            System.out.println("[KeepAlive] " + LocalDateTime.now() + " - Ping retornou status: " + response.statusCode());
                        }
                    })
                    .exceptionally(e -> {
                        System.err.println("[KeepAlive] Erro ao fazer ping: " + e.getMessage());
                        return null;
                    });
        } catch (Exception e) {
            System.err.println("[KeepAlive] Exceção ao tentar ping: " + e.getMessage());
        }
    }
}
