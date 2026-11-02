package com.example.apiProjeto.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

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
    private final AtomicReference<String> ultimaBuscaWikipedia = new AtomicReference<>("");
    private boolean groundingRetornaFontes = true;
    private boolean falhaRespostaFinal;
    private HttpServer server;
    private ConsultaBotanicaService service;

    @BeforeEach
    void iniciarServidorDeTeste() throws IOException {
        chamadasAgente.set(0);
        chamadasWikipedia.set(0);
        ultimaBuscaWikipedia.set("");
        groundingRetornaFontes = true;
        falhaRespostaFinal = false;
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/w/api.php", exchange -> {
            chamadasWikipedia.incrementAndGet();
            String query = exchange.getRequestURI().getRawQuery();
            if (query != null && query.contains("pageids=")) {
                responder(exchange, ultimaBuscaWikipedia.get().toLowerCase().contains("abacaxi")
                        ? """
                                {"query":{"pages":{"42":{"extract":"Ananas comosus é uma espécie tropical cultivada."}}}}
                                """
                        : """
                                {"query":{"pages":{"42":{"extract":"Pepino japonês é uma espécie cultivada em hortas."}}}}
                                """);
            } else {
                ultimaBuscaWikipedia.set(query == null ? "" : query);
                boolean termoPepinoLimpo = query != null
                        && query.toLowerCase().contains("pepino")
                        && !query.toLowerCase().contains("cadastrar")
                        && !query.toLowerCase().contains("quero");
                boolean termoAbacaxi = query != null && query.toLowerCase().contains("abacaxi");
                if (termoPepinoLimpo || termoAbacaxi) {
                    responder(exchange, termoPepinoLimpo ? """
                            {"query":{"search":[{"pageid":42,"title":"Pepino japonês"}]}}
                            """ : """
                            {"query":{"search":[{"pageid":42,"title":"Abacaxi"}]}}
                            """);
                } else {
                    responder(exchange, """
                            {"query":{"search":[]}}
                            """);
                }
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

    @Test
    void usaFontesExternasQuandoProvedorFalhaNaRespostaFinal() {
        falhaRespostaFinal = true;
        groundingRetornaFontes = false;

        Map<String, Object> resposta = service.consultar(
                "", "Eu quero cadastrar um pepino japonês, mas não sei os dados min e max "
                        + "para cadastrar, poderia consultar por favor.", null, null, List.of());

        assertTrue(resposta.get("relatorio").toString().contains("informações em fontes externas"));
        assertTrue(resposta.get("relatorio").toString().contains("Pepino japonês"));
        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(1, fontes.size());
        assertEquals("pepino japonês", fontes.path(0).path("termoBusca").asText());
        assertTrue(ultimaBuscaWikipedia.get().contains("pepino+japon%C3%AAs"));
        assertTrue(!ultimaBuscaWikipedia.get().contains("cadastrar"));
    }

    @Test
    void preservaAnaliseQuandoPedidoDeCadastroNaoTemFaixasSuficientes() {
        Map<String, Object> resposta = service.consultar(
                "pepino", "Quero cadastrar pepino.", null, null, List.of());

        String relatorio = resposta.get("relatorio").toString();
        assertTrue(relatorio.contains("Resposta final baseada na fonte."));
        assertTrue(relatorio.contains("Não foi preparado nem salvo um cadastro."));
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
            if (falhaRespostaFinal) {
                responder(exchange, 503, """
                        {"error":{"message":"Serviço de IA temporariamente indisponível."}}
                        """);
                return;
            }

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
        responder(exchange, 200, corpo);
    }

    private void responder(HttpExchange exchange, int status, String corpo) throws IOException {
        byte[] bytes = corpo.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
