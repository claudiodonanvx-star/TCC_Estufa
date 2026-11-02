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
    private final AtomicReference<String> solicitacaoPesquisaGoogle = new AtomicReference<>("");
    private boolean groundingRetornaFontes = true;
    private boolean groundingSemTrechos;
    private boolean falhaRespostaFinal;
    private boolean agenteChamaFerramenta = true;
    private HttpServer server;
    private ConsultaBotanicaService service;

    @BeforeEach
    void iniciarServidorDeTeste() throws IOException {
        chamadasAgente.set(0);
        chamadasWikipedia.set(0);
        ultimaBuscaWikipedia.set("");
        solicitacaoPesquisaGoogle.set("");
        groundingRetornaFontes = true;
        groundingSemTrechos = false;
        falhaRespostaFinal = false;
        agenteChamaFerramenta = true;
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
    void buscaFontesAntesDaRespostaMesmoQuandoAgenteNaoChamaFerramenta() {
        agenteChamaFerramenta = false;

        Map<String, Object> resposta = service.consultar(
                "abacaxi", "Quais cuidados são recomendados para o abacaxi?", null, null, List.of());

        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(1, fontes.size());
        assertEquals("https://www.embrapa.br/publicacoes/cultivo-abacaxi",
                fontes.path(0).path("url").asText());
        assertEquals("Resposta final baseada na fonte.", resposta.get("relatorio"));
    }

    @Test
    void preparaPropostaDePepinoComEstimativaDeSoloSemQuestionario() {
        agenteChamaFerramenta = false;

        Map<String, Object> resposta = service.consultar(
                "Pepino",
                "Quero cadastrar pepino e consultar os dados externos.",
                null,
                null,
                List.of());

        @SuppressWarnings("unchecked")
        Map<String, Object> proposta =
                (Map<String, Object>) resposta.get("cadastroPendente");
        assertTrue(proposta != null);
        @SuppressWarnings("unchecked")
        Map<String, Object> cultivo = (Map<String, Object>) proposta.get("cultivo");
        assertEquals(18, cultivo.get("temperaturaMinima"));
        assertEquals(30, cultivo.get("temperaturaMaxima"));
        assertEquals(70, cultivo.get("umidadeMinima"));
        assertEquals(90, cultivo.get("umidadeMaxima"));
        assertEquals(60, cultivo.get("umidadeSoloMinima"));
        assertEquals(80, cultivo.get("umidadeSoloMaxima"));
        assertEquals(false, cultivo.get("habilitada"));
        assertEquals(true, proposta.get("umidadeSoloEstimada"));
        assertTrue(proposta.get("observacao").toString().contains("estimativa"));
        assertEquals(1, objectMapper.valueToTree(proposta.get("fontes")).size());
        assertTrue(solicitacaoPesquisaGoogle.get().contains("Quero cadastrar pepino"));
    }

    @Test
    void naoUsaWikipediaComoEvidenciaDeFaixasDeCultivo() {
        groundingRetornaFontes = false;

        Map<String, Object> resposta = service.consultar(
                "abacaxi", "Quais cuidados são recomendados para o abacaxi?", null, null, List.of());

        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(0, fontes.size());
        assertEquals(0, chamadasWikipedia.get());
    }

    @Test
    void pesquisaFaixasQuandoNomeDaPlantaEstaNaPergunta() {
        agenteChamaFerramenta = false;

        Map<String, Object> resposta = service.consultar(
                "", "Quais os dados min e max do meu lírio da paz?", null, null, List.of());

        assertTrue(solicitacaoPesquisaGoogle.get().contains("lírio da paz"));
        assertTrue(solicitacaoPesquisaGoogle.get().contains("umidade relativa do ar"));
        assertTrue(solicitacaoPesquisaGoogle.get().contains("umidade da zona radicular"));
        assertTrue(solicitacaoPesquisaGoogle.get().contains("Quais os dados min e max"));
        assertEquals(1, objectMapper.valueToTree(resposta.get("fontes")).size());
        assertEquals(0, chamadasWikipedia.get());
    }

    @Test
    void buscaLirioAranhaSemCampoPlantaEExibeLinksMesmoSemTrechosDeCitacao() {
        agenteChamaFerramenta = false;
        groundingSemTrechos = true;

        Map<String, Object> resposta = service.consultar(
                "",
                "Eu quero cadastrar lírio aranha no sistema, mas não sei direito as infos, "
                        + "poderia pesquisar os requisitos dela para a estufa por favor?",
                null,
                null,
                List.of());

        assertTrue(solicitacaoPesquisaGoogle.get().contains("planta lírio aranha"));
        assertTrue(solicitacaoPesquisaGoogle.get().contains("nomes comuns em outros idiomas"));
        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(1, fontes.size());
        assertEquals("lírio aranha", fontes.path(0).path("termoBusca").asText());
        assertEquals("https://plants.ces.ncsu.edu/plants/lycoris-radiata/",
                fontes.path(0).path("url").asText());
        assertEquals("", fontes.path(0).path("resumo").asText());
        assertEquals(0, chamadasWikipedia.get());
    }

    @Test
    void preparaPropostaDeLirioAranhaComFaixasDeBaixaConfiancaEConfirmaçãoDeRisco() {
        agenteChamaFerramenta = false;
        groundingRetornaFontes = false;

        Map<String, Object> resposta = service.consultar(
                "",
                "Eu quero cadastrar lírio aranha no sistema, mas não sei direito as infos, "
                        + "poderia pesquisar os requisitos dela para a estufa por favor?",
                null,
                null,
                List.of());

        @SuppressWarnings("unchecked")
        Map<String, Object> proposta =
                (Map<String, Object>) resposta.get("cadastroPendente");
        assertTrue(proposta != null);
        assertEquals(true, proposta.get("estimativaNaoVerificada"));
        @SuppressWarnings("unchecked")
        Map<String, Object> cultivo = (Map<String, Object>) proposta.get("cultivo");
        assertEquals("lírio aranha", cultivo.get("nome"));
        assertEquals(15.0, cultivo.get("temperaturaMinima"));
        assertEquals(24.0, cultivo.get("temperaturaMaxima"));
        assertEquals(40.0, cultivo.get("umidadeMinima"));
        assertEquals(60.0, cultivo.get("umidadeMaxima"));
        assertEquals(60, cultivo.get("umidadeSoloMinima"));
        assertEquals(80, cultivo.get("umidadeSoloMaxima"));
        assertTrue(proposta.get("observacao").toString().contains("baixa confiança"));
        assertTrue(proposta.get("observacao").toString().contains("assume o risco"));
        assertTrue(resposta.get("relatorio").toString().contains("preparei uma proposta"));
    }

    @Test
    void preparaPropostaGenericaDeFlorSemFontesConfiaveis() {
        agenteChamaFerramenta = false;
        groundingRetornaFontes = false;

        Map<String, Object> resposta = service.consultar(
                "",
                "Quero cadastrar flor-de-cera (Hoya carnosa) na estufa, mas não conheço as condições.",
                null,
                null,
                List.of());

        assertTrue(solicitacaoPesquisaGoogle.get().contains("planta flor-de-cera"));
        @SuppressWarnings("unchecked")
        Map<String, Object> proposta =
                (Map<String, Object>) resposta.get("cadastroPendente");
        assertTrue(proposta != null);
        assertEquals(true, proposta.get("estimativaNaoVerificada"));
        @SuppressWarnings("unchecked")
        Map<String, Object> cultivo = (Map<String, Object>) proposta.get("cultivo");
        assertEquals("flor-de-cera", cultivo.get("nome"));
        assertEquals(15.0, cultivo.get("temperaturaMinima"));
        assertEquals(30.0, cultivo.get("temperaturaMaxima"));
        assertEquals(40.0, cultivo.get("umidadeMinima"));
        assertEquals(70.0, cultivo.get("umidadeMaxima"));
        assertEquals(60, cultivo.get("umidadeSoloMinima"));
        assertEquals(80, cultivo.get("umidadeSoloMaxima"));
        assertTrue(proposta.get("observacao").toString().contains("genéricas"));
        assertTrue(proposta.get("observacao").toString().contains("assume o risco"));
    }

    @Test
    void usaFontesExternasQuandoProvedorFalhaNaRespostaFinal() {
        falhaRespostaFinal = true;
        groundingRetornaFontes = false;

        Map<String, Object> resposta = service.consultar(
                "", "Eu quero cadastrar um pepino japonês, mas não sei os dados min e max "
                        + "para cadastrar, poderia consultar por favor.", null, null, List.of());

        JsonNode fontes = objectMapper.valueToTree(resposta.get("fontes"));
        assertEquals(0, fontes.size());
        assertTrue(resposta.get("relatorio").toString().contains("fontes externas verificáveis"));
        assertEquals(0, chamadasWikipedia.get());
    }

    @Test
    void preservaAnaliseQuandoPedidoDeCadastroNaoTemFaixasSuficientes() {
        Map<String, Object> resposta = service.consultar(
                "pepino", "Quero cadastrar pepino.", null, null, List.of());

        String relatorio = resposta.get("relatorio").toString();
        assertTrue(relatorio.contains("Resposta final baseada na fonte."));
        assertTrue(resposta.containsKey("cadastroPendente"));
    }

    private void responderGemini(HttpExchange exchange) throws IOException {
        JsonNode requisicao = objectMapper.readTree(exchange.getRequestBody().readAllBytes());
        String ferramentas = requisicao.path("tools").toString();
        if (ferramentas.contains("google_search")) {
            solicitacaoPesquisaGoogle.set(requisicao.toString());
            if (groundingSemTrechos) {
                responder(exchange, """
                        {
                          "candidates": [{
                            "content": {"role":"model","parts":[{"text":"A página da extensão universitária descreve cultivo em solo rico, úmido e bem drenado."}]},
                            "groundingMetadata": {
                              "groundingChunks": [{
                                "web": {
                                  "title":"Red spider lily - NC State Extension",
                                  "uri":"https://plants.ces.ncsu.edu/plants/lycoris-radiata/"
                                }
                              }]
                            }
                          }]
                        }
                        """);
                return;
            }
            boolean consultaPepino = requisicao.toString().toLowerCase().contains("pepino");
            if (consultaPepino && groundingRetornaFontes) {
                responder(exchange, """
                        {
                          "candidates": [{
                            "content": {"role":"model","parts":[{"text":"Para o pepino, são recomendados 18 a 30 graus e umidade relativa do ar entre 70% e 90%."}]},
                            "groundingMetadata": {
                              "groundingChunks": [{
                                "web": {
                                  "title":"Exigências climáticas para o cultivo de pepino",
                                  "uri":"https://www.tecnologiaetreinamento.com.br/agricultura/exigencias-climaticas-para-o-cultivo-de-pepino/"
                                }
                              }],
                              "groundingSupports": [{
                                "segment":{"text":"Para o pepino, temperaturas de 18 a 30 °C e umidade relativa do ar entre 70% e 90%."},
                                "groundingChunkIndices":[0]
                              }]
                            }
                          }]
                        }
                        """);
                return;
            }
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

            responder(exchange, agenteChamaFerramenta ? """
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
                    """ : """
                    {
                      "candidates": [{
                        "content": {
                          "role":"model",
                          "parts":[{"text":"Resposta final baseada na fonte."}]
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
