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
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.example.apiProjeto.model.Alerta;
import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.model.RelatorioDiario;
import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.AlertaRepository;
import com.example.apiProjeto.repository.CultivoRepository;
import com.example.apiProjeto.repository.RelatorioDiarioRepository;
import com.example.apiProjeto.repository.SensorDataRepository;
import com.example.apiProjeto.service.AtuadorService;
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
        private final SensorDataRepository sensorDataRepository;
        private final CultivoRepository cultivoRepository;
        private final AlertaRepository alertaRepository;
        private final RelatorioDiarioRepository relatorioRepository;
        private final AtuadorService atuadorService;
        private final ConsultaBancoLeituraService consultaBancoLeituraService;

    public ConsultaBotanicaService(ObjectMapper objectMapper,
                                   @Value("${app.ai.api-key:}") String aiApiKey,
                                   @Value("${app.ai.endpoint:}") String aiEndpoint,
                                   @Value("${app.ai.model:gemini-2.5-flash}") String aiModel,
                                                                   @Value("${app.ai.provider:gemini}") String aiProvider,
                                                                   SensorDataRepository sensorDataRepository,
                                                                   CultivoRepository cultivoRepository,
                                                                   AlertaRepository alertaRepository,
                                                                   RelatorioDiarioRepository relatorioRepository,
                                                                   AtuadorService atuadorService,
                                                                   ConsultaBancoLeituraService consultaBancoLeituraService) {
        this.objectMapper = objectMapper;
        this.aiApiKey = aiApiKey;
        this.aiEndpoint = aiEndpoint;
        this.aiModel = aiModel;
                this.aiProvider = aiProvider;
                this.sensorDataRepository = sensorDataRepository;
                this.cultivoRepository = cultivoRepository;
                this.alertaRepository = alertaRepository;
                this.relatorioRepository = relatorioRepository;
                this.atuadorService = atuadorService;
                this.consultaBancoLeituraService = consultaBancoLeituraService;
    }

    public Map<String, Object> consultar(String planta, String pergunta,
                                                                                 Double umidadeAtual, Double temperaturaAtual,
                                                                                 List<Map<String, String>> historico) {
        String termo = planta == null || planta.isBlank() ? pergunta : planta;
        String analiseLocal = gerarAnaliseLocal(planta, pergunta, umidadeAtual, temperaturaAtual);

        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("planta", termo);
        resposta.put("pergunta", pergunta);
        resposta.put("analiseLocal", analiseLocal);
        resposta.put("fontes", List.of());

        if (!aiApiKey.isBlank()) {
            ResultadoIA resultadoIA = gerarRelatorioComIA(planta, pergunta, umidadeAtual,
                    temperaturaAtual, analiseLocal, historico);
            resposta.put("relatorio", resultadoIA.texto());
            resposta.put("tipo", "agente com ferramentas internas");
        } else {
            resposta.put("relatorio", "O agente não está configurado para interpretar solicitações. "
                    + "Configure AI_API_KEY no servidor para ativar o agente e suas ferramentas internas.");
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

        private ResultadoIA gerarRelatorioComIA(String planta, String pergunta, Double umidade,
                                                                                        Double temperatura, String analiseLocal,
                                                                                        List<Map<String, String>> historico) {
        try {
            String conversa = objectMapper.writeValueAsString(historico);
                        String prompt = "Você é o assistente da Estufa Smart. Responda em português, com clareza e objetividade. "
                                        + "O usuário pode perguntar qualquer coisa sobre dados e recursos internos do sistema. "
                                        + "Quando a resposta depender de dados atuais ou armazenados, escolha e chame a ferramenta interna "
                                        + "adequada antes de responder. Para buscas que não se encaixem nas consultas específicas, use "
                                        + "consultar_dados_operacionais_banco. Nunca invente valores, datas, cultivos ou estados. "
                                        + "As ferramentas consultam somente dados operacionais em modo de leitura; não tente acessar "
                                        + "usuários, clientes, credenciais ou outras tabelas. Se nenhuma ferramenta for necessária, responda normalmente. "
                                        + "Pergunta atual: " + pergunta + ". Planta informada: " + planta
                                        + ". Umidade informada: " + umidade + ". Temperatura informada: " + temperatura
                                        + ". Análise botânica local disponível: " + analiseLocal
                                        + ". Histórico recente: " + conversa;
            if ("gemini".equalsIgnoreCase(aiProvider)) {
                                return new ResultadoIA(gerarComGemini(prompt), List.of());
            }
                        return new ResultadoIA(gerarComOpenAi(prompt), List.of());
        } catch (Exception erro) {
                        return new ResultadoIA("Não consegui concluir a consulta agora. Tente novamente em instantes.", List.of());
        }
    }

        private record ResultadoIA(String texto, List<Map<String, String>> fontes) {}

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
        List<Map<String, Object>> contents = new ArrayList<>();
        contents.add(Map.of("role", "user", "parts", List.of(Map.of("text", prompt))));

        for (int rodada = 0; rodada < 4; rodada++) {
            Map<String, Object> body = Map.of(
                    "tools", List.of(Map.of("functionDeclarations", declaracoesGemini())),
                    "contents", contents);
            JsonNode resposta = objectMapper.readTree(post(endpoint,
                    objectMapper.writeValueAsString(body), null));
            validarResposta(resposta);
            JsonNode candidato = resposta.path("candidates").path(0);
            JsonNode conteudo = candidato.path("content");
            List<JsonNode> chamadas = new ArrayList<>();
            for (JsonNode parte : conteudo.path("parts")) {
                if (parte.has("functionCall")) {
                    chamadas.add(parte.path("functionCall"));
                }
            }
            if (chamadas.isEmpty()) {
                StringBuilder texto = new StringBuilder();
                for (JsonNode parte : conteudo.path("parts")) {
                    if (parte.has("text")) texto.append(parte.path("text").asText());
                }
                return textoOuFallback(texto.toString(), "Não consegui formular uma resposta para a consulta.");
            }

            contents.add(objectMapper.convertValue(conteudo, Map.class));
            List<Map<String, Object>> respostasFerramentas = new ArrayList<>();
            for (JsonNode chamada : chamadas) {
                String nome = chamada.path("name").asText();
                Map<String, Object> resultado = executarFerramenta(nome, chamada.path("args"));
                respostasFerramentas.add(Map.of("functionResponse", Map.of(
                        "name", nome,
                        "response", resultado)));
            }
            contents.add(Map.of("role", "user", "parts", respostasFerramentas));
        }
        return "A consulta exigiu muitas etapas e não pôde ser concluída. Tente uma pergunta mais específica.";
    }

    private String gerarComOpenAi(String prompt) throws Exception {
        String endpoint = aiEndpoint.isBlank() ? "https://api.openai.com/v1/chat/completions" : aiEndpoint;
        List<Map<String, Object>> mensagens = new ArrayList<>();
        mensagens.add(Map.of("role", "user", "content", prompt));

        for (int rodada = 0; rodada < 4; rodada++) {
            Map<String, Object> body = Map.of(
                    "model", aiModel,
                    "temperature", 0.2,
                    "messages", mensagens,
                    "tools", declaracoesOpenAi(),
                    "tool_choice", "auto");
            JsonNode resposta = objectMapper.readTree(post(endpoint,
                    objectMapper.writeValueAsString(body), "Bearer " + aiApiKey));
            validarResposta(resposta);
            JsonNode mensagem = resposta.path("choices").path(0).path("message");
            JsonNode chamadas = mensagem.path("tool_calls");
            if (!chamadas.isArray() || chamadas.isEmpty()) {
                return textoOuFallback(mensagem.path("content").asText(""),
                        "Não consegui formular uma resposta para a consulta.");
            }

            mensagens.add(objectMapper.convertValue(mensagem, Map.class));
            for (JsonNode chamada : chamadas) {
                String nome = chamada.path("function").path("name").asText();
                JsonNode argumentos = objectMapper.readTree(
                        chamada.path("function").path("arguments").asText("{}"));
                Map<String, Object> resultado = executarFerramenta(nome, argumentos);
                mensagens.add(Map.of(
                        "role", "tool",
                        "tool_call_id", chamada.path("id").asText(),
                        "content", objectMapper.writeValueAsString(resultado)));
            }
        }
        return "A consulta exigiu muitas etapas e não pôde ser concluída. Tente uma pergunta mais específica.";
    }

    private List<Map<String, Object>> declaracoesGemini() {
        return List.of(
                declaracao("consultar_leituras_sensores", "Consulta leituras de sensores armazenadas. "
                                + "Use quantidade 1 para descobrir quando o último dado foi registrado.", true),
                declaracao("consultar_total_leituras", "Informa quantas leituras de sensores estão armazenadas.", true),
                declaracao("consultar_cultivo_ativo", "Consulta os limites do cultivo atualmente habilitado.", true),
                declaracao("listar_cultivos", "Lista os cultivos cadastrados no sistema.", true),
                declaracao("consultar_alertas", "Consulta os alertas recentes, opcionalmente filtrados por severidade.", true),
                declaracao("consultar_relatorios", "Consulta os relatórios diários mais recentes.", true),
                declaracao("consultar_estado_atuadores", "Consulta o modo e o estado atual dos atuadores.", true),
                declaracaoConsultaBanco());
    }

    private Map<String, Object> declaracaoConsultaBanco() {
        return Map.of(
                "name", "consultar_dados_operacionais_banco",
                "description", "Executa uma busca somente leitura diretamente no banco de dados operacional, sem depender de rotas específicas da API. Escolha uma tabela permitida; resultados são limitados a 50 linhas. Nunca use para buscar dados de usuários, clientes ou credenciais.",
                "parameters", Map.of(
                        "type", "OBJECT",
                        "properties", Map.of(
                                "tabela", Map.of(
                                        "type", "STRING",
                                        "enum", List.of("sensor_data", "cultivos", "alertas", "relatorio_diario"),
                                        "description", "Tabela operacional permitida."),
                                "termo", Map.of(
                                        "type", "STRING",
                                        "description", "Texto parcial para sensor_data, cultivos e alertas; data exata AAAA-MM-DD para relatorio_diario."),
                                "quantidade", Map.of(
                                        "type", "INTEGER",
                                        "description", "Quantidade máxima de linhas entre 1 e 50."),
                                "ordem", Map.of(
                                        "type", "STRING",
                                        "enum", List.of("recentes", "antigos"),
                                        "description", "Ordenação por data ou identificador.")),
                        "required", List.of("tabela")));
    }

    private List<Map<String, Object>> declaracoesOpenAi() {
        return declaracoesGemini().stream()
                                .map(declaracao -> {
                                        @SuppressWarnings("unchecked")
                                        Map<String, Object> parametrosGemini = (Map<String, Object>) declaracao.get("parameters");
                                        Map<String, Object> propriedadesGemini = (Map<String, Object>) parametrosGemini.get("properties");
                                        Map<String, Object> propriedadesOpenAi = new LinkedHashMap<>();
                                        propriedadesGemini.forEach((nome, propriedade) -> {
                                                @SuppressWarnings("unchecked")
                                                Map<String, Object> campoGemini = (Map<String, Object>) propriedade;
                                                Map<String, Object> campoOpenAi = new LinkedHashMap<>(campoGemini);
                                                campoOpenAi.computeIfPresent("type", (chave, valor) -> valor.toString().toLowerCase(Locale.ROOT));
                                                propriedadesOpenAi.put(nome, campoOpenAi);
                                        });
                                        @SuppressWarnings("unchecked")
                                        List<String> camposObrigatorios =
                                                        (List<String>) parametrosGemini.getOrDefault("required", List.of());
                                        Map<String, Object> parametrosOpenAi = Map.of(
                                                        "type", "object", "properties", propriedadesOpenAi,
                                                        "required", camposObrigatorios);
                                        Map<String, Object> funcao = Map.of(
                                                        "name", declaracao.get("name"),
                                                        "description", declaracao.get("description"),
                                                        "parameters", parametrosOpenAi);
                                        return Map.<String, Object>of("type", "function", "function", funcao);
                                })
                .toList();
    }

    private Map<String, Object> declaracao(String nome, String descricao, boolean gemini) {
        String tipoObjeto = gemini ? "OBJECT" : "object";
        String tipoInteiro = gemini ? "INTEGER" : "integer";
        String tipoString = gemini ? "STRING" : "string";
        Map<String, Object> parametros = Map.of(
                "type", tipoObjeto,
                "properties", Map.of(
                        "quantidade", Map.of("type", tipoInteiro, "description", "Quantidade de itens; máximo 50."),
                        "ordem", Map.of("type", tipoString, "enum", List.of("recentes", "antigos")),
                        "severidade", Map.of("type", tipoString, "enum", List.of("CRITICO", "ATENCAO"))));
        return Map.of("name", nome, "description", descricao, "parameters", parametros);
    }

    private Map<String, Object> executarFerramenta(String nome, JsonNode argumentos) {
        int quantidade = Math.max(1, Math.min(50, argumentos.path("quantidade").asInt(1)));
        String ordem = argumentos.path("ordem").asText("recentes");
        return switch (nome) {
            case "consultar_leituras_sensores" -> {
                Sort.Direction direcao = "antigos".equalsIgnoreCase(ordem)
                        ? Sort.Direction.ASC : Sort.Direction.DESC;
                List<SensorData> leituras = sensorDataRepository.findAll(PageRequest.of(0, quantidade,
                        Sort.by(direcao, "coletadoEm").and(Sort.by(direcao, "id")))).getContent();
                List<Map<String, Object>> itens = leituras.stream().map(leitura -> Map.<String, Object>of(
                        "id", leitura.getId() == null ? 0L : leitura.getId(),
                        "registradoEm", leitura.getColetadoEm() == null ? "data não informada" : leitura.getColetadoEm().toString(),
                        "temperaturaC", leitura.getTemperatura(),
                        "umidadeArPercentual", leitura.getUmidade(),
                        "umidadeSoloPercentual", leitura.getUmidadeSolo() == null ? "indisponível" : leitura.getUmidadeSolo())).toList();
                yield Map.of("quantidadeRetornada", itens.size(), "leituras", itens);
            }
            case "consultar_total_leituras" -> Map.of("totalLeituras", sensorDataRepository.count());
            case "consultar_cultivo_ativo" -> {
                Cultivo cultivo = cultivoRepository.findFirstByHabilitadaTrueOrderByIdDesc();
                yield cultivo == null ? Map.of("mensagem", "Não há cultivo ativo.") : Map.of(
                        "nome", cultivo.getNome(), "tipo", cultivo.getTipo(),
                        "temperaturaMinima", cultivo.getTemperaturaMinima(),
                        "temperaturaMaxima", cultivo.getTemperaturaMaxima(),
                        "umidadeMinima", cultivo.getUmidadeMinima(),
                        "umidadeMaxima", cultivo.getUmidadeMaxima(),
                        "umidadeSoloMinima", cultivo.getUmidadeSoloMinima(),
                        "umidadeSoloMaxima", cultivo.getUmidadeSoloMaxima());
            }
            case "listar_cultivos" -> Map.of("cultivos", cultivoRepository.findAll().stream().map(cultivo -> Map.of(
                    "nome", cultivo.getNome(), "tipo", cultivo.getTipo(),
                    "habilitada", cultivo.isHabilitada())).toList());
            case "consultar_alertas" -> {
                String severidade = argumentos.path("severidade").asText("");
                List<Alerta> alertas = Set.of("CRITICO", "ATENCAO").contains(severidade.toUpperCase(Locale.ROOT))
                        ? alertaRepository.findTop20BySeveridadeOrderByGeradoEmDesc(severidade.toUpperCase(Locale.ROOT))
                        : alertaRepository.findTop100ByOrderByGeradoEmDesc().stream().limit(quantidade).toList();
                yield Map.of("alertas", alertas.stream().map(alerta -> Map.of(
                        "severidade", alerta.getSeveridade(), "tipo", alerta.getTipo(),
                        "valor", alerta.getValor(), "mensagem", alerta.getMensagem() == null ? "" : alerta.getMensagem(),
                        "registradoEm", alerta.getGeradoEm() == null ? "data não informada" : alerta.getGeradoEm().toString())).toList());
            }
            case "consultar_relatorios" -> {
                Sort.Direction direcao = "antigos".equalsIgnoreCase(ordem)
                        ? Sort.Direction.ASC : Sort.Direction.DESC;
                List<RelatorioDiario> relatorios = relatorioRepository.findAll(
                        PageRequest.of(0, quantidade, Sort.by(direcao, "dataRef"))).getContent();
                yield Map.of("relatorios", relatorios.stream().map(relatorio -> Map.of(
                        "data", relatorio.getDataRef().toString(),
                        "temperaturaMedia", relatorio.getTempMedia(),
                        "umidadeMedia", relatorio.getUmidadeMedia(),
                        "umidadeSoloMedia", relatorio.getSoloMedia(),
                        "totalLeituras", relatorio.getTotalLeituras())).toList());
            }
            case "consultar_estado_atuadores" -> atuadorService.obterEstado();
            case "consultar_dados_operacionais_banco" -> consultaBancoLeituraService.consultar(
                    argumentos.path("tabela").asText(""),
                    argumentos.path("termo").asText(""),
                    quantidade,
                    ordem);
            default -> Map.of("erro", "Ferramenta interna não permitida.");
        };
    }

    private void validarResposta(JsonNode resposta) {
        if (resposta.has("error")) {
            throw new IllegalStateException(resposta.path("error").path("message")
                    .asText("O provedor de IA recusou a solicitação."));
        }
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