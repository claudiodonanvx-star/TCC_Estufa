package com.example.apiProjeto.service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class ConsultaBotanicaService {

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8)).build();
    private final ObjectMapper objectMapper;
    private final String aiApiKey;
    private final String aiEndpoint;
    private final String aiModel;

    public ConsultaBotanicaService(ObjectMapper objectMapper,
                                   @Value("${app.ai.api-key:}") String aiApiKey,
                                   @Value("${app.ai.endpoint:https://api.openai.com/v1/chat/completions}") String aiEndpoint,
                                   @Value("${app.ai.model:gpt-4o-mini}") String aiModel) {
        this.objectMapper = objectMapper;
        this.aiApiKey = aiApiKey;
        this.aiEndpoint = aiEndpoint;
        this.aiModel = aiModel;
    }

    public Map<String, Object> consultar(String planta, String pergunta,
                                         Double umidadeAtual, Double temperaturaAtual) {
        String termo = planta == null || planta.isBlank() ? pergunta : planta;
        List<Map<String, String>> fontes = buscarFontes(termo);
        String analiseLocal = gerarAnaliseLocal(planta, umidadeAtual);

        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("planta", termo);
        resposta.put("pergunta", pergunta);
        resposta.put("analiseLocal", analiseLocal);
        resposta.put("fontes", fontes);

        if (!aiApiKey.isBlank()) {
            String relatorio = gerarRelatorioComIA(planta, pergunta, umidadeAtual,
                    temperaturaAtual, fontes, analiseLocal);
            resposta.put("relatorio", relatorio);
            resposta.put("tipo", "IA com consulta de fontes na internet");
        } else {
            resposta.put("relatorio", analiseLocal
                    + " Configure AI_API_KEY no ambiente da API para gerar um relatório narrativo com IA.");
            resposta.put("tipo", "consulta de fontes + análise local");
        }
        return resposta;
    }

    private List<Map<String, String>> buscarFontes(String termo) {
        List<Map<String, String>> fontes = new ArrayList<>();
        try {
            String url = "https://pt.wikipedia.org/w/api.php?action=query&list=search&srsearch="
                    + URLEncoder.encode(termo + " planta cultivo umidade", StandardCharsets.UTF_8)
                    + "&format=json&utf8=1&srlimit=3";
            JsonNode busca = objectMapper.readTree(get(url));
            for (JsonNode item : busca.path("query").path("search")) {
                String titulo = item.path("title").asText();
                fontes.add(Map.of(
                        "titulo", titulo,
                        "url", "https://pt.wikipedia.org/wiki/"
                                + URLEncoder.encode(titulo.replace(' ', '_'), StandardCharsets.UTF_8),
                        "resumo", limparHtml(item.path("snippet").asText())
                ));
            }
        } catch (Exception erro) {
            fontes.add(Map.of("titulo", "Busca indisponível", "url", "", "resumo",
                    "Não foi possível consultar a fonte externa agora."));
        }
        return fontes;
    }

    private String gerarRelatorioComIA(String planta, String pergunta, Double umidade,
                                       Double temperatura, List<Map<String, String>> fontes,
                                       String analiseLocal) {
        try {
            String contexto = objectMapper.writeValueAsString(fontes);
            String prompt = "Você é um assistente agrícola. Responda em português, de forma prática e prudente. "
                    + "Use somente as fontes fornecidas como contexto, indique quando houver incerteza e não invente dados. "
                    + "Gere um pequeno relatório com: recomendação de umidade, justificativa, cuidados e fontes. "
                    + "Planta: " + planta + ". Pergunta: " + pergunta + ". Umidade atual: " + umidade
                    + ". Temperatura atual: " + temperatura + ". Análise local: " + analiseLocal
                    + ". Fontes: " + contexto;
            Map<String, Object> body = Map.of(
                    "model", aiModel,
                    "temperature", 0.2,
                    "messages", List.of(Map.of("role", "user", "content", prompt))
            );
            JsonNode resposta = objectMapper.readTree(post(aiEndpoint,
                    objectMapper.writeValueAsString(body), "Bearer " + aiApiKey));
            return resposta.path("choices").path(0).path("message").path("content")
                    .asText(analiseLocal);
        } catch (Exception erro) {
            return analiseLocal + " A geração narrativa por IA está temporariamente indisponível.";
        }
    }

    private String gerarAnaliseLocal(String planta, Double umidadeAtual) {
        if (umidadeAtual == null) {
            return "Para recomendar a umidade com mais precisão, informe a umidade atual e a fase da planta. "
                    + "A faixa ideal varia conforme espécie, substrato, clima e estágio de crescimento.";
        }
        if (umidadeAtual < 35) {
            return "A umidade atual está baixa para muitas plantas cultivadas; verifique o substrato antes de irrigar "
                    + "e evite encharcar. A faixa exata depende da espécie " + planta + ".";
        }
        if (umidadeAtual > 80) {
            return "A umidade atual está alta e pode favorecer excesso de água; verifique drenagem e ventilação. "
                    + "A faixa exata depende da espécie " + planta + ".";
        }
        return "A umidade atual está em uma faixa intermediária. Compare a leitura com a recomendação específica da espécie "
                + planta + " e observe o substrato antes de ajustar a irrigação.";
    }

    private String get(String url) throws Exception {
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(10)).header("Accept", "application/json").GET().build();
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString()).body();
    }

    private String post(String url, String body, String authorization) throws Exception {
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(20)).header("Content-Type", "application/json")
                .header("Authorization", authorization)
                .POST(HttpRequest.BodyPublishers.ofString(body)).build();
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString()).body();
    }

    private String limparHtml(String texto) {
        return texto.replaceAll("<[^>]*>", "").replace("&quot;", "\"")
                .replace("&amp;", "&").replace("&#039;", "'");
    }
}