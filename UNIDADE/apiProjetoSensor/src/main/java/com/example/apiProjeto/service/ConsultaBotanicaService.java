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
import java.util.Locale;

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
        private final String aiProvider;

    public ConsultaBotanicaService(ObjectMapper objectMapper,
                                   @Value("${app.ai.api-key:}") String aiApiKey,
                                   @Value("${app.ai.endpoint:}") String aiEndpoint,
                                   @Value("${app.ai.model:gemini-2.0-flash}") String aiModel,
                                   @Value("${app.ai.provider:gemini}") String aiProvider) {
        this.objectMapper = objectMapper;
        this.aiApiKey = aiApiKey;
        this.aiEndpoint = aiEndpoint;
        this.aiModel = aiModel;
                this.aiProvider = aiProvider;
    }

    public Map<String, Object> consultar(String planta, String pergunta,
                                                                                 Double umidadeAtual, Double temperaturaAtual,
                                                                                 List<Map<String, String>> historico) {
                String termo = planta == null || planta.isBlank() ? pergunta : planta;
        List<Map<String, String>> fontes = buscarFontes(termo);
                String analiseLocal = gerarAnaliseLocal(planta, pergunta, umidadeAtual, temperaturaAtual);

        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("planta", termo);
        resposta.put("pergunta", pergunta);
        resposta.put("analiseLocal", analiseLocal);
        resposta.put("fontes", fontes);

        if (!aiApiKey.isBlank()) {
            String relatorio = gerarRelatorioComIA(planta, pergunta, umidadeAtual,
                    temperaturaAtual, fontes, analiseLocal, historico);
            resposta.put("relatorio", relatorio);
            resposta.put("tipo", "agente agrícola com IA e consulta de fontes");
        } else {
            resposta.put("relatorio", analiseLocal
                    + " Configure AI_API_KEY no Render para ativar o agente generativo.");
            resposta.put("tipo", "modo local sem chave de IA");
        }
        return resposta;
    }

    private List<Map<String, String>> buscarFontes(String termo) {
        List<Map<String, String>> fontes = new ArrayList<>();
        try {
            String url = "https://pt.wikipedia.org/w/api.php?action=query&list=search&srsearch="
                    + URLEncoder.encode(termo + " planta cultivo", StandardCharsets.UTF_8)
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
                                       String analiseLocal, List<Map<String, String>> historico) {
        try {
            String contexto = objectMapper.writeValueAsString(fontes);
            String conversa = objectMapper.writeValueAsString(historico);
            String tema = identificarTema(pergunta);
            String prompt = "Você é o Agente Agrícola da Estufa Smart. Responda em português, de forma prática, "
                    + "didática e prudente. Você deve responder exatamente ao tema perguntado, sem trocar temperatura "
                    + "por umidade. Identifique a intenção do usuário antes de responder. "
                    + "Use somente as fontes fornecidas como contexto, indique quando houver incerteza e não invente dados. "
                    + "Gere um relatório com: resposta direta, faixa ou procedimento recomendado, justificativa, cuidados, "
                    + "limitações e fontes. Tema identificado: " + tema + ". "
                    + "Planta: " + planta + ". Pergunta: " + pergunta + ". Umidade atual: " + umidade
                    + ". Temperatura atual: " + temperatura + ". Análise local: " + analiseLocal
                    + ". Fontes: " + contexto + ". Histórico da conversa: " + conversa;
            if ("gemini".equalsIgnoreCase(aiProvider)) {
                                return textoOuFallback(gerarComGemini(prompt), analiseLocal);
            }
                        return textoOuFallback(gerarComOpenAi(prompt), analiseLocal);
        } catch (Exception erro) {
            return analiseLocal + " A geração narrativa por IA está temporariamente indisponível.";
        }
    }

        private String textoOuFallback(String texto, String fallback) {
                return texto == null || texto.isBlank()
                                ? fallback + " O agente não recebeu texto do provedor de IA nesta tentativa."
                                : texto;
        }

        private String gerarAnaliseLocal(String planta, String pergunta, Double umidadeAtual,
                                                                         Double temperaturaAtual) {
                String tema = identificarTema(pergunta);
                if ("temperatura".equals(tema)) {
                        if (temperaturaAtual == null) {
                                return "Para responder sobre temperatura, informe a temperatura atual e a fase da planta. "
                                                + "A faixa ideal depende da espécie, fase de crescimento e ambiente.";
                        }
                        return temperaturaAtual < 15
                                        ? "A temperatura atual está baixa para muitas plantas; proteja a cultura e confirme a faixa da espécie " + planta + "."
                                        : temperaturaAtual > 32
                                        ? "A temperatura atual está alta; aumente a ventilação e avalie sombreamento para a espécie " + planta + "."
                                        : "A temperatura atual está em uma faixa moderada. Compare-a com a recomendação específica da espécie " + planta + ".";
                }
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

        private String identificarTema(String pergunta) {
                String texto = pergunta == null ? "" : pergunta.toLowerCase(Locale.ROOT);
                if (texto.contains("temperatura") || texto.contains("quente") || texto.contains("frio")) {
                        return "temperatura";
                }
                if (texto.contains("solo") || texto.contains("irrig") || texto.contains("regar")) {
                        return "solo e irrigação";
                }
                if (texto.contains("umidade") || texto.contains("úmido") || texto.contains("umido")) {
                        return "umidade";
                }
                return "cuidados gerais da planta";
        }

        private String gerarComGemini(String prompt) throws Exception {
                String endpoint = aiEndpoint.isBlank()
                                ? "https://generativelanguage.googleapis.com/v1beta/models/"
                                        + aiModel + ":generateContent?key=" + URLEncoder.encode(aiApiKey, StandardCharsets.UTF_8)
                                : aiEndpoint;
                Map<String, Object> body = Map.of("contents", List.of(Map.of(
                                "role", "user",
                                "parts", List.of(Map.of("text", prompt)))));
                JsonNode resposta = objectMapper.readTree(post(endpoint,
                                objectMapper.writeValueAsString(body), null));
                return resposta.path("candidates").path(0).path("content").path("parts").path(0)
                        .path("text").asText("");
        }

        private String gerarComOpenAi(String prompt) throws Exception {
                String endpoint = aiEndpoint.isBlank() ? "https://api.openai.com/v1/chat/completions" : aiEndpoint;
                Map<String, Object> body = Map.of("model", aiModel, "temperature", 0.2,
                                "messages", List.of(Map.of("role", "user", "content", prompt)));
                JsonNode resposta = objectMapper.readTree(post(endpoint,
                                objectMapper.writeValueAsString(body), "Bearer " + aiApiKey));
                return resposta.path("choices").path(0).path("message").path("content").asText("");
        }

    private String get(String url) throws Exception {
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(10)).header("Accept", "application/json").GET().build();
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString()).body();
    }

        private String post(String url, String body, String authorization) throws Exception {
                HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url))
                                .timeout(Duration.ofSeconds(20)).header("Content-Type", "application/json");
                if (authorization != null && !authorization.isBlank()) {
                        builder.header("Authorization", authorization);
                }
                HttpRequest request = builder.POST(HttpRequest.BodyPublishers.ofString(body)).build();
        return httpClient.send(request, HttpResponse.BodyHandlers.ofString()).body();
    }

    private String limparHtml(String texto) {
        return texto.replaceAll("<[^>]*>", "").replace("&quot;", "\"")
                .replace("&amp;", "&").replace("&#039;", "'");
    }
}