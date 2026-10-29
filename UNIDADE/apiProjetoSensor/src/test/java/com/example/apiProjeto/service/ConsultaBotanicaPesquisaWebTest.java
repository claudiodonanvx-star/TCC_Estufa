package com.example.apiProjeto.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import com.example.apiProjeto.repository.AlertaRepository;
import com.example.apiProjeto.repository.CultivoRepository;
import com.example.apiProjeto.repository.RelatorioDiarioRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ConsultaBotanicaPesquisaWebTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicInteger chamadasAgente = new AtomicInteger();
    private final AtomicInteger chamadasWikipedia = new AtomicInteger();
    private boolean groundingRetornaFontes = true;
    private HttpServer server;
    private ConsultaBotanicaService service;

    @BeforeEach
    void iniciarServidorDeTeste() throws IOException {
        chamadasAgente.set(0);
        chamadasWikipedia.set(0);
        groundingRetornaFontes = true;
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/w/api.php", exchange -> {
            chamadasWikipedia.incrementAndGet();
            String query = exchange.getRequestURI().getRawQuery();
            if (query != null && query.contains("pageids=")) {
                responder(exchange, """
                        {"query":{"pages":{"42":{"extract":"Ananas comosus é uma espécie tropical cultivada."}}}}
                        """);
            } else {
                responder(exchange, """
                        {"query":{"search":[{"pageid":42,"title":"Abacaxi"}]}}
                        """);
            }
        });
        server.createContext("/gemini", this::responderGemini);
        server.start();

        String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        service = new ConsultaBotanicaService(
                objectMapper,
                "test-api-key",
                baseUrl + "/gemini",
                "gemini-2.5-flash",
                "gemini",
                baseUrl + "/w/api.php",
                mock(SensorDataRepository.class),
                mock(CultivoRepository.class),
                mock(AlertaRepository.class),
                mock(RelatorioDiarioRepository.class),
                mock(AtuadorService.class),
                mock(ConsultaBancoLeituraService.class));
    }

    @AfterEach
    void pararServidorDeTeste() {
        server.stop(0);
    }

    @Test
    void buscarFontesPesquisaNaWebERetornaCitacoesParaOAgente() throws Exception {
        Map<String, Object> resposta = service.consultar(
                "abacaxi", "Quais cuidados são recomendados para o abacaxi?", null, null, List.of());

        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(1, fontes.size());
        assertEquals("Cultivo do abacaxi - Embrapa", fontes.path(0).path("titulo").asText());
        assertEquals("https://www.embrapa.br/publicacoes/cultivo-abacaxi",
                fontes.path(0).path("url").asText());
        assertEquals("A Embrapa informa que o abacaxi é cultivado em clima quente.",
                fontes.path(0).path("resumo").asText());
        assertEquals("abacaxi", fontes.path(0).path("termoBusca").asText());
        assertEquals(0, chamadasWikipedia.get());
        assertEquals("Resposta final baseada na fonte.", resposta.get("relatorio"));
    }

    @Test
    void usaWikipediaComoFallbackQuandoPesquisaWebNaoRetornaCitacoes() {
        groundingRetornaFontes = false;

        Map<String, Object> resposta = service.consultar(
                "abacaxi", "Quais cuidados são recomendados para o abacaxi?", null, null, List.of());

        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(1, fontes.size());
        assertEquals("Abacaxi", fontes.path(0).path("titulo").asText());
        assertEquals("Ananas comosus é uma espécie tropical cultivada.",
                fontes.path(0).path("resumo").asText());
        assertEquals(2, chamadasWikipedia.get());
    }

    private void responderGemini(HttpExchange exchange) throws IOException {
        JsonNode requisicao = objectMapper.readTree(exchange.getRequestBody().readAllBytes());
        String ferramentas = requisicao.path("tools").toString();
        if (ferramentas.contains("google_search")) {
            responder(exchange, groundingRetornaFontes ? """
                    {
                      "candidates": [{
                        "content": {"role":"model","parts":[{"text":"A pesquisa encontrou recomendações técnicas para o cultivo do abacaxi."}]},
                        "groundingMetadata": {
                          "groundingChunks": [{
                            "web": {
                              "title":"Cultivo do abacaxi - Embrapa",
                              "uri":"https://www.embrapa.br/publicacoes/cultivo-abacaxi"
                            }
                          }],
                          "groundingSupports": [{
                            "segment":{"text":"A Embrapa informa que o abacaxi é cultivado em clima quente."},
                            "groundingChunkIndices":[0]
                          }]
                        }
                      }]
                    }
                      """ : """
                      {
                        "candidates": [{
                          "content": {"role":"model","parts":[{"text":"A pesquisa não encontrou fontes citáveis."}]}
                        }]
                      }
                      """);
            return;
        }

        if (chamadasAgente.getAndIncrement() == 0) {
            responder(exchange, """
                    {
                      "candidates": [{
                        "content": {
                          "role":"model",
                          "parts":[{
                            "functionCall":{
                              "name":"buscar_fontes_cultivo",
                              "args":{"termo":"abacaxi"}
                            }
                          }]
                        }
                      }]
                    }
                    """);
            return;
        }

        responder(exchange, """
                {
                  "candidates": [{
                    "content": {
                      "role":"model",
                      "parts":[{"text":"Resposta final baseada na fonte."}]
                    }
                  }]
                }
                """);
    }

    private void responder(HttpExchange exchange, String corpo) throws IOException {
        byte[] bytes = corpo.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(200, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
