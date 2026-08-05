package br.com.estufa.desktop.service;

import br.com.estufa.desktop.model.Alerta;
import br.com.estufa.desktop.model.Cultivo;
import br.com.estufa.desktop.model.RelatorioDiario;
import br.com.estufa.desktop.model.SensorData;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;

public class ApiService {
    private static final String DEFAULT_BASE_URL = "https://api-estufa.onrender.com";

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final String baseUrl;

    public ApiService() {
        this.baseUrl = System.getProperty("estufa.api.baseUrl", DEFAULT_BASE_URL);
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.objectMapper = new ObjectMapper();
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public LoginResult login(String cpf, String senha) throws IOException, InterruptedException {
        String payload = objectMapper.writeValueAsString(new LoginRequest(cpf, senha));

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/usuarios/login"))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(12))
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        JsonNode node = parseJsonOrEmpty(response.body());

        if (response.statusCode() >= 200 && response.statusCode() < 300) {
            String cpfResp = textOrDefault(node, "cpf", cpf);
            boolean admin = node.path("administrador").asBoolean(false);
            String mensagem = textOrDefault(node, "mensagem", "Login bem-sucedido");
            long pendencias = node.path("pendenciasAprovacao").asLong(0L);
            return new LoginResult(cpfResp, admin, mensagem, pendencias);
        }

        String message = textOrDefault(node, "mensagem", "Falha no login (HTTP " + response.statusCode() + ")");
        throw new IllegalStateException(message);
    }

    public boolean isApiOnline() {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/ping"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return response.statusCode() >= 200 && response.statusCode() < 300;
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    public List<SensorData> fetchSensorData() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/dados"))
                .timeout(Duration.ofSeconds(12))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        ensureOk(response.statusCode(), response.body(), "/api/dados");

        return objectMapper.readValue(response.body(), new TypeReference<>() {});
    }

    public Cultivo fetchCultivoHabilitado() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/cultivo-habilitado"))
                .timeout(Duration.ofSeconds(12))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        ensureOk(response.statusCode(), response.body(), "/api/cultivo-habilitado");

        if (response.body() == null || response.body().isBlank() || response.body().equals("null")) {
            return null;
        }
        return objectMapper.readValue(response.body(), Cultivo.class);
    }

    public List<RelatorioDiario> fetchRelatoriosSemanal() throws IOException, InterruptedException {
        return fetchRelatorios("/api/relatorios/semanal");
    }

    public List<RelatorioDiario> fetchRelatoriosMensal() throws IOException, InterruptedException {
        return fetchRelatorios("/api/relatorios/mensal");
    }

    public List<RelatorioDiario> fetchRelatoriosAnual() throws IOException, InterruptedException {
        return fetchRelatorios("/api/relatorios/anual");
    }

    private List<RelatorioDiario> fetchRelatorios(String endpoint) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + endpoint))
                .timeout(Duration.ofSeconds(12))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        ensureOk(response.statusCode(), response.body(), endpoint);
        return objectMapper.readValue(response.body(), new TypeReference<>() {});
    }

    public String triggerConsolidar(String data) throws IOException, InterruptedException {
        String payload = data != null ? "{\"data\":\"" + data + "\"}" : "{}";
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/relatorios/consolidar"))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(30))
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        JsonNode node = parseJsonOrEmpty(response.body());
        return textOrDefault(node, "mensagem", "Consolidacao executada.");
    }

    public String fetchRelatoriosCsv(String tipo) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/relatorios/export/csv?tipo=" + tipo))
                .timeout(Duration.ofSeconds(30))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        ensureOk(response.statusCode(), response.body(), "/api/relatorios/export/csv");
        return response.body();
    }

    public List<Alerta> fetchAlertas() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/alertas"))
                .timeout(Duration.ofSeconds(12))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        ensureOk(response.statusCode(), response.body(), "/api/alertas");
        return objectMapper.readValue(response.body(), new TypeReference<>() {});
    }

    /** Retorna info do /api/ping: status, versao, uptimeMinutos, totalLeituras, alertas24h */
    public JsonNode fetchPingInfo() throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/ping"))
                .timeout(Duration.ofSeconds(5))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        return parseJsonOrEmpty(response.body());
    }

    private void ensureOk(int statusCode, String body, String endpoint) {
        if (statusCode < 200 || statusCode >= 300) {
            throw new IllegalStateException("Falha ao consumir " + endpoint + " (HTTP " + statusCode + ")\n" + body);
        }
    }

    private JsonNode parseJsonOrEmpty(String body) throws IOException {
        if (body == null || body.isBlank()) {
            return objectMapper.createObjectNode();
        }
        return objectMapper.readTree(body);
    }

    private String textOrDefault(JsonNode node, String field, String defaultValue) {
        if (node.has(field) && !node.get(field).isNull()) {
            String value = node.get(field).asText();
            return value == null || value.isBlank() ? defaultValue : value;
        }
        return defaultValue;
    }

    private record LoginRequest(String login, String senha) {
    }

    public record LoginResult(String cpf, boolean administrador, String mensagem, long pendenciasAprovacao) {
    }
}
