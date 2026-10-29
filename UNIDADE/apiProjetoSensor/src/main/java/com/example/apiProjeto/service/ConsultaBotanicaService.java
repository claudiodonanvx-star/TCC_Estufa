package com.example.apiProjeto.service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
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

    private static final System.Logger LOGGER =
            System.getLogger(ConsultaBotanicaService.class.getName());
    private static final int MAXIMO_RODADAS_FERRAMENTAS = 8;
    private static final int MAXIMO_FONTES_EXTERNAS = 5;
    private static final Pattern NUMERO_PATTERN = Pattern.compile("(?<![\\d])\\d+(?:[.,]\\d+)?(?![\\d])");

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8)).build();
    private final ObjectMapper objectMapper;
    private final String aiApiKey;
    private final String aiEndpoint;
    private final String aiModel;
        private final String aiProvider;
        private final String wikipediaEndpoint;
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
                                                                   @Value("${app.ai.wikipedia-endpoint:https://pt.wikipedia.org/w/api.php}")
                                                                   String wikipediaEndpoint,
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
        this.wikipediaEndpoint = wikipediaEndpoint;
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
            String textoResposta = resultadoIA.texto();
            if (solicitaCadastro(pergunta)) {
                textoResposta = resultadoIA.cadastroPendente() == null
                        ? "Não foi preparado nem salvo um cadastro. Não consegui confirmar todas as faixas "
                                + "de temperatura, umidade do ar e umidade do solo. Informe os valores ou peça "
                                + "uma pesquisa externa com fontes verificáveis."
                        : textoResposta + "\n\nA proposta ainda não foi salva; confirme no botão abaixo.";
            }
            resposta.put("relatorio", textoResposta);
            resposta.put("tipo", "agente com ferramentas internas");
            resposta.put("fontes", resultadoIA.fontes());
            if (resultadoIA.cadastroPendente() != null) {
                resposta.put("cadastroPendente", resultadoIA.cadastroPendente());
            }
            if (resultadoIA.arquivoUrl() != null) {
                resposta.put("arquivoUrl", resultadoIA.arquivoUrl());
                resposta.put("arquivoNome", resultadoIA.arquivoNome());
            }
        } else {
            resposta.put("relatorio", "O agente não está configurado para interpretar solicitações. "
                    + "Configure AI_API_KEY no servidor para ativar o agente e suas ferramentas internas.");
            resposta.put("tipo", "modo local sem chave de IA");
        }
        return resposta;
    }

    private boolean solicitaCadastro(String pergunta) {
        String texto = normalizarTexto(pergunta);
        return !texto.startsWith("como ")
                && (texto.contains("cadastre")
                        || texto.contains("cadastrar")
                        || texto.contains("registre")
                        || texto.contains("registrar")
                        || texto.contains("adicione")
                        || texto.contains("adicionar")
                        || texto.contains("inclua")
                        || texto.contains("incluir"));
    }

    private List<Map<String, String>> buscarFontes(String termo) throws Exception {
        if ("gemini".equalsIgnoreCase(aiProvider) && !aiApiKey.isBlank()) {
            try {
                List<Map<String, String>> fontesGoogle = buscarFontesGoogle(termo);
                if (!fontesGoogle.isEmpty()) {
                    return fontesGoogle;
                }
            } catch (Exception erro) {
                LOGGER.log(System.Logger.Level.WARNING,
                        "A pesquisa Google do Gemini falhou; usando a fonte externa alternativa.", erro);
            }
        }

        return buscarFontesWikipedia(termo);
    }

    private List<Map<String, String>> buscarFontesGoogle(String termo) throws Exception {
        String endpoint = endpointGemini();
        String prompt = "Pesquise na web informações confiáveis sobre " + termo
                + " para responder uma pergunta sobre cultivo. Priorize fontes técnicas "
                + "oficiais, como Embrapa, universidades, órgãos públicos e institutos de pesquisa. "
                + "Resuma somente informações sustentadas pelas fontes e cite as fontes consultadas.";
        Map<String, Object> body = Map.of(
                "tools", List.of(Map.of("google_search", Map.of())),
                "contents", List.of(Map.of(
                        "role", "user",
                        "parts", List.of(Map.of("text", prompt)))));
        JsonNode resposta = objectMapper.readTree(post(
                endpoint, objectMapper.writeValueAsString(body), null));
        validarResposta(resposta);

        JsonNode candidato = resposta.path("candidates").path(0);
        Map<Integer, Map<String, String>> fontesPorIndice = new LinkedHashMap<>();
        JsonNode chunks = candidato.path("groundingMetadata").path("groundingChunks");
        for (int indice = 0; indice < chunks.size(); indice++) {
            JsonNode web = chunks.path(indice).path("web");
            String titulo = web.path("title").asText("");
            String url = web.path("uri").asText("");
            if (!titulo.isBlank() && urlValida(url)) {
                Map<String, String> fonte = new LinkedHashMap<>();
                fonte.put("titulo", titulo);
                fonte.put("url", url);
                fonte.put("resumo", "");
                fontesPorIndice.put(indice, fonte);
            }
        }

        for (JsonNode suporte : candidato.path("groundingMetadata").path("groundingSupports")) {
            String trecho = suporte.path("segment").path("text").asText("").trim();
            if (trecho.isEmpty()) {
                continue;
            }
            for (JsonNode indiceNode : suporte.path("groundingChunkIndices")) {
                Map<String, String> fonte = fontesPorIndice.get(indiceNode.asInt(-1));
                if (fonte != null && fonte.get("resumo").length() < 4000) {
                    String resumo = fonte.get("resumo");
                    fonte.put("resumo", resumo.isEmpty() ? trecho
                            : resumo + " " + trecho);
                }
            }
        }
        return fontesPorIndice.values().stream()
                .filter(fonte -> !fonte.get("resumo").isBlank())
                .limit(MAXIMO_FONTES_EXTERNAS)
                .map(Map::copyOf)
                .toList();
    }

    private boolean urlValida(String valor) {
        try {
            URI uri = URI.create(valor);
            return uri.getHost() != null
                    && ("https".equalsIgnoreCase(uri.getScheme())
                            || "http".equalsIgnoreCase(uri.getScheme()));
        } catch (IllegalArgumentException erro) {
            return false;
        }
    }

    private String endpointGemini() {
        return aiEndpoint.isBlank()
                ? "https://generativelanguage.googleapis.com/v1beta/models/"
                        + aiModel + ":generateContent?key="
                        + URLEncoder.encode(aiApiKey, StandardCharsets.UTF_8)
                : aiEndpoint;
    }

    private List<Map<String, String>> buscarFontesWikipedia(String termo) throws Exception {
        String urlBusca = wikipediaEndpoint + "?action=query&list=search&srsearch="
                + URLEncoder.encode(termo + " cultivo", StandardCharsets.UTF_8)
                + "&format=json&utf8=1&srlimit=3";
        JsonNode busca = objectMapper.readTree(get(urlBusca));
        List<String> ids = new ArrayList<>();
        Map<String, String> titulos = new LinkedHashMap<>();
        for (JsonNode item : busca.path("query").path("search")) {
            String id = item.path("pageid").asText();
            ids.add(id);
            titulos.put(id, item.path("title").asText());
        }
        if (ids.isEmpty()) {
            return List.of();
        }

        String urlExtratos = wikipediaEndpoint + "?action=query&pageids="
                + String.join("|", ids)
                + "&prop=extracts&exintro=1&explaintext=1&format=json&utf8=1";
        JsonNode paginas = objectMapper.readTree(get(urlExtratos)).path("query").path("pages");
        List<Map<String, String>> fontes = new ArrayList<>();
        for (String id : ids) {
            JsonNode pagina = paginas.path(id);
            String titulo = titulos.get(id);
            String extrato = pagina.path("extract").asText("").trim();
            if (!extrato.isEmpty()) {
                fontes.add(Map.of(
                        "titulo", titulo,
                        "url", "https://pt.wikipedia.org/wiki/"
                                + URLEncoder.encode(titulo.replace(' ', '_'), StandardCharsets.UTF_8),
                        "resumo", extrato.length() > 4000 ? extrato.substring(0, 4000) : extrato));
            }
        }
        return fontes;
    }

        private ResultadoIA gerarRelatorioComIA(String planta, String pergunta, Double umidade,
                                                                                        Double temperatura, String analiseLocal,
                                                                                        List<Map<String, String>> historico) {
        try {
            String conversa = objectMapper.writeValueAsString(historico);
                        String dadosInformadosPeloUsuario = pergunta + " " + historico.stream()
                                        .filter(mensagem -> "usuario".equalsIgnoreCase(mensagem.get("papel")))
                                        .map(mensagem -> mensagem.getOrDefault("texto", ""))
                                        .reduce("", (a, b) -> a + " " + b);
                        String prompt = "Você é o assistente da Estufa Smart. Responda em português, com clareza e objetividade. "
                                        + "O usuário pode perguntar qualquer coisa sobre dados e recursos internos do sistema. "
                                        + "Quando a resposta depender de dados atuais ou armazenados, escolha e chame a ferramenta interna "
                                        + "adequada antes de responder. Para buscas que não se encaixem nas consultas específicas, use "
                                        + "consultar_dados_operacionais_banco e use os filtros de intervalo quando a pergunta citar datas. "
                                        + "Para perguntas factuais sobre plantas, cultivo, condições ideais, identificação ou doenças, "
                                        + "use buscar_fontes_cultivo antes de responder, mesmo que já conheça o assunto. Baseie as "
                                        + "afirmações botânicas nos trechos e URLs retornados, cite as fontes e não alegue que pesquisou "
                                        + "se não recebeu resultados verificáveis. "
                                        + "Para pedidos de arquivo CSV ou PDF, use gerar_relatorio_arquivo e informe o período pedido; "
                                        + "períodos relativos como 'últimos 5 dias' devem ser convertidos em datas ISO. "
                                        + "Nunca invente valores, datas, cultivos, faixas agronômicas ou estados. "
                                        + "Para cadastrar uma planta: se o usuário forneceu todas as seis faixas, use a origem usuario; "
                                        + "se faltarem faixas, pesquise na web com buscar_fontes_cultivo e use somente valores numéricos "
                                        + "presentes nos textos retornados. Se as fontes não trouxerem todos os valores, não os estime: "
                                        + "peça ao usuário os valores ausentes. Prepare o cadastro com preparar_cadastro_cultivo, "
                                        + "mas nunca diga que foi salvo: o usuário precisa confirmar no botão da aplicação. "
                                        + "As ferramentas consultam somente dados operacionais em modo de leitura; não tente acessar "
                                        + "usuários, clientes, credenciais ou outras tabelas. Se nenhuma ferramenta for necessária, responda normalmente. "
                                        + "A data de hoje é " + LocalDate.now() + ". "
                                        + "Pergunta atual: " + pergunta + ". Planta informada: " + planta
                                        + ". Umidade informada: " + umidade + ". Temperatura informada: " + temperatura
                                        + ". Análise botânica local disponível: " + analiseLocal
                                        + ". Histórico recente: " + conversa;
            if ("gemini".equalsIgnoreCase(aiProvider)) {
                                return gerarComGemini(prompt, dadosInformadosPeloUsuario);
            }
                        return gerarComOpenAi(prompt, dadosInformadosPeloUsuario);
        } catch (Exception erro) {
                        LOGGER.log(System.Logger.Level.ERROR, "Falha ao consultar o agente da estufa.", erro);
                        return new ResultadoIA(
                                "Não consegui concluir a consulta agora. Tente novamente em instantes.",
                                null, null, null, List.of());
        }
    }

        private record ResultadoIA(
                String texto,
                String arquivoUrl,
                String arquivoNome,
                Map<String, Object> cadastroPendente,
                List<Map<String, String>> fontes) {}

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

    private ResultadoIA gerarComGemini(String prompt, String dadosInformadosPeloUsuario) throws Exception {
        String endpoint = endpointGemini();
        List<Map<String, Object>> contents = new ArrayList<>();
        contents.add(Map.of("role", "user", "parts", List.of(Map.of("text", prompt))));

        String arquivoUrl = null;
        String arquivoNome = null;
        Map<String, Object> cadastroPendente = null;
        List<Map<String, String>> fontesExternas = new ArrayList<>();
        for (int rodada = 0; rodada < MAXIMO_RODADAS_FERRAMENTAS; rodada++) {
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
                return new ResultadoIA(
                        textoOuFallback(texto.toString(), "Não consegui formular uma resposta para a consulta."),
                        arquivoUrl,
                        arquivoNome,
                        cadastroPendente,
                        List.copyOf(fontesExternas));
            }

            contents.add(objectMapper.convertValue(conteudo, Map.class));
            List<Map<String, Object>> respostasFerramentas = new ArrayList<>();
            for (JsonNode chamada : chamadas) {
                String nome = chamada.path("name").asText();
                Map<String, Object> resultado = executarFerramenta(
                        nome, chamada.path("args"), dadosInformadosPeloUsuario, fontesExternas);
                registrarResultadoFerramenta(nome, resultado, fontesExternas);
                Object proposta = resultado.get("cadastroPendente");
                if (proposta instanceof Map<?, ?> mapaProposta) {
                    cadastroPendente = mapaComoTextoObjeto(mapaProposta);
                }
                if (resultado.containsKey("arquivoUrl")) {
                    arquivoUrl = resultado.get("arquivoUrl").toString();
                    arquivoNome = resultado.get("arquivoNome").toString();
                }
                respostasFerramentas.add(Map.of("functionResponse", Map.of(
                        "name", nome,
                        "response", resultado)));
            }
            contents.add(Map.of("role", "user", "parts", respostasFerramentas));
        }
        return new ResultadoIA(
                "A consulta ainda não foi concluída após várias buscas. Tente pedir uma informação por vez.",
                arquivoUrl,
                arquivoNome,
                cadastroPendente,
                List.copyOf(fontesExternas));
    }

    private ResultadoIA gerarComOpenAi(String prompt, String dadosInformadosPeloUsuario) throws Exception {
        String endpoint = aiEndpoint.isBlank() ? "https://api.openai.com/v1/chat/completions" : aiEndpoint;
        List<Map<String, Object>> mensagens = new ArrayList<>();
        mensagens.add(Map.of("role", "user", "content", prompt));

        String arquivoUrl = null;
        String arquivoNome = null;
        Map<String, Object> cadastroPendente = null;
        List<Map<String, String>> fontesExternas = new ArrayList<>();
        for (int rodada = 0; rodada < MAXIMO_RODADAS_FERRAMENTAS; rodada++) {
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
                return new ResultadoIA(
                        textoOuFallback(mensagem.path("content").asText(""),
                                "Não consegui formular uma resposta para a consulta."),
                        arquivoUrl,
                        arquivoNome,
                        cadastroPendente,
                        List.copyOf(fontesExternas));
            }

            mensagens.add(objectMapper.convertValue(mensagem, Map.class));
            for (JsonNode chamada : chamadas) {
                String nome = chamada.path("function").path("name").asText();
                JsonNode argumentos = objectMapper.readTree(
                        chamada.path("function").path("arguments").asText("{}"));
                Map<String, Object> resultado = executarFerramenta(
                        nome, argumentos, dadosInformadosPeloUsuario, fontesExternas);
                registrarResultadoFerramenta(nome, resultado, fontesExternas);
                Object proposta = resultado.get("cadastroPendente");
                if (proposta instanceof Map<?, ?> mapaProposta) {
                    cadastroPendente = mapaComoTextoObjeto(mapaProposta);
                }
                if (resultado.containsKey("arquivoUrl")) {
                    arquivoUrl = resultado.get("arquivoUrl").toString();
                    arquivoNome = resultado.get("arquivoNome").toString();
                }
                mensagens.add(Map.of(
                        "role", "tool",
                        "tool_call_id", chamada.path("id").asText(),
                        "content", objectMapper.writeValueAsString(resultado)));
            }
        }
        return new ResultadoIA(
                "A consulta ainda não foi concluída após várias buscas. Tente pedir uma informação por vez.",
                arquivoUrl,
                arquivoNome,
                cadastroPendente,
                List.copyOf(fontesExternas));
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
                declaracaoConsultaBanco(),
                declaracaoGerarRelatorio(),
                declaracaoBuscaCultivo(),
                declaracaoPrepararCadastroCultivo());
    }

    private Map<String, Object> declaracaoBuscaCultivo() {
        return Map.of(
                "name", "buscar_fontes_cultivo",
                "description", "Pesquisa a web em tempo real com Google Search para encontrar páginas técnicas externas, priorizando Embrapa, universidades, órgãos públicos e institutos de pesquisa; retorna trechos citados e URLs. Use antes de responder perguntas botânicas factuais ou sugerir faixas não fornecidas pelo usuário. Não invente valores que não estejam nos trechos.",
                "parameters", Map.of(
                        "type", "OBJECT",
                        "properties", Map.of(
                                "termo", Map.of("type", "STRING",
                                        "description", "Nome científico ou comum do cultivo a pesquisar.")),
                        "required", List.of("termo")));
    }

    private Map<String, Object> declaracaoPrepararCadastroCultivo() {
        return Map.of(
                "name", "preparar_cadastro_cultivo",
                "description", "Prepara uma proposta de cadastro, sem gravar no banco. Use somente se os seis limites foram informados pelo usuário ou podem ser verificados nos trechos externos pesquisados nesta conversa. Cadastro só é salvo após confirmação explícita do usuário na aplicação.",
                "parameters", Map.of(
                        "type", "OBJECT",
                        "properties", Map.of(
                                "nome", Map.of("type", "STRING", "description", "Nome do cultivo."),
                                "tipo", Map.of("type", "STRING", "description", "Tipo/categoria da planta."),
                                "temperaturaMinima", Map.of("type", "NUMBER"),
                                "temperaturaMaxima", Map.of("type", "NUMBER"),
                                "umidadeMinima", Map.of("type", "NUMBER"),
                                "umidadeMaxima", Map.of("type", "NUMBER"),
                                "umidadeSoloMinima", Map.of("type", "NUMBER"),
                                "umidadeSoloMaxima", Map.of("type", "NUMBER"),
                                "origem", Map.of("type", "STRING", "enum", List.of("usuario", "externa"))),
                        "required", List.of("nome", "tipo", "temperaturaMinima", "temperaturaMaxima",
                                "umidadeMinima", "umidadeMaxima", "umidadeSoloMinima",
                                "umidadeSoloMaxima", "origem")));
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
                                "inicio", Map.of(
                                        "type", "STRING",
                                        "description", "Data inicial inclusiva do filtro, no formato AAAA-MM-DD."),
                                "fim", Map.of(
                                        "type", "STRING",
                                        "description", "Data final inclusiva do filtro, no formato AAAA-MM-DD."),
                                "quantidade", Map.of(
                                        "type", "INTEGER",
                                        "description", "Quantidade máxima de linhas entre 1 e 50."),
                                "ordem", Map.of(
                                        "type", "STRING",
                                        "enum", List.of("recentes", "antigos"),
                                        "description", "Ordenação por data ou identificador.")),
                        "required", List.of("tabela")));
    }

    private Map<String, Object> declaracaoGerarRelatorio() {
        return Map.of(
                "name", "gerar_relatorio_arquivo",
                "description", "Gera um arquivo CSV ou PDF para download com dados operacionais do banco. Use para pedidos explícitos de exportação. Informe o período inclusivo em datas AAAA-MM-DD e escolha a tabela operacional. A exportação aceita até 31 dias e 5000 linhas.",
                "parameters", Map.of(
                        "type", "OBJECT",
                        "properties", Map.of(
                                "tabela", Map.of(
                                        "type", "STRING",
                                        "enum", List.of("sensor_data", "alertas", "relatorio_diario"),
                                        "description", "Tabela operacional com data a exportar; use sensor_data para leituras."),
                                "inicio", Map.of(
                                        "type", "STRING",
                                        "description", "Data inicial inclusiva no formato AAAA-MM-DD."),
                                "fim", Map.of(
                                        "type", "STRING",
                                        "description", "Data final inclusiva no formato AAAA-MM-DD."),
                                "formato", Map.of(
                                        "type", "STRING",
                                        "enum", List.of("csv", "pdf"),
                                        "description", "Formato do arquivo solicitado.")),
                        "required", List.of("tabela", "inicio", "fim", "formato")));
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

    private Map<String, Object> executarFerramenta(
            String nome,
            JsonNode argumentos,
            String dadosInformadosPeloUsuario,
            List<Map<String, String>> fontesExternas) throws Exception {
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
                    dataOpcional(argumentos, "inicio"),
                    dataOpcional(argumentos, "fim"),
                    quantidade,
                    ordem);
            case "gerar_relatorio_arquivo" -> gerarLinkRelatorio(argumentos);
            case "buscar_fontes_cultivo" -> {
                String termo = argumentos.path("termo").asText("").trim();
                List<Map<String, String>> fontes = buscarFontes(termo).stream()
                        .map(fonte -> {
                            Map<String, String> fonteComTermo = new LinkedHashMap<>(fonte);
                            fonteComTermo.put("termoBusca", termo);
                            return fonteComTermo;
                        })
                        .toList();
                yield Map.of("fontes", fontes);
            }
            case "preparar_cadastro_cultivo" -> prepararCadastroCultivo(
                    argumentos, dadosInformadosPeloUsuario, fontesExternas);
            default -> Map.of("erro", "Ferramenta interna não permitida.");
        };
    }

    Map<String, Object> prepararCadastroCultivo(
            JsonNode argumentos,
            String dadosInformadosPeloUsuario,
            List<Map<String, String>> fontesExternas) {
        String nome = argumentos.path("nome").asText("").trim();
        String tipo = argumentos.path("tipo").asText("").trim();
        String origem = argumentos.path("origem").asText("");
        if (nome.isBlank() || tipo.isBlank()) {
            return Map.of("erro", "Informe o nome e o tipo do cultivo.");
        }

        Map<String, Double> faixas = new LinkedHashMap<>();
        for (String campo : List.of(
                "temperaturaMinima", "temperaturaMaxima", "umidadeMinima",
                "umidadeMaxima", "umidadeSoloMinima", "umidadeSoloMaxima")) {
            double valor = argumentos.path(campo).asDouble(Double.NaN);
            if (!Double.isFinite(valor)) {
                return Map.of("erro", "Faltam valores numéricos completos para as seis faixas.");
            }
            faixas.put(campo, valor);
        }
        if (faixas.get("temperaturaMinima") < 0
                || faixas.get("temperaturaMaxima") < faixas.get("temperaturaMinima")
                || faixas.get("umidadeMinima") < 0 || faixas.get("umidadeMaxima") > 100
                || faixas.get("umidadeMaxima") < faixas.get("umidadeMinima")
                || faixas.get("umidadeSoloMinima") < 0 || faixas.get("umidadeSoloMaxima") > 100
                || faixas.get("umidadeSoloMaxima") < faixas.get("umidadeSoloMinima")) {
            return Map.of("erro", "As faixas são inválidas; confira mínimos, máximos e percentuais entre 0 e 100.");
        }
        boolean valoresDoUsuario = "usuario".equalsIgnoreCase(origem)
                && faixas.values().stream().allMatch(valor -> contémNumero(dadosInformadosPeloUsuario, valor));
        List<Map<String, String>> fontesDoCultivo = fontesExternas.stream()
                .filter(fonte -> buscaCorrespondeAoCultivo(fonte.get("termoBusca"), nome))
                .toList();
        boolean valoresDeFonte = "externa".equalsIgnoreCase(origem)
                && !fontesDoCultivo.isEmpty()
                && faixas.values().stream().allMatch(valor -> fontesExternas.stream()
                        .anyMatch(fonte -> buscaCorrespondeAoCultivo(fonte.get("termoBusca"), nome)
                                && contémNumero(fonte.get("resumo"), valor)));
        if (!valoresDoUsuario && !valoresDeFonte) {
            return Map.of("erro", "Não consegui verificar todas as faixas na mensagem do usuário ou nas fontes consultadas. "
                    + "Não vou preparar um cadastro com valores estimados; informe os valores ausentes.");
        }
        boolean duplicado = cultivoRepository.findAll().stream()
                .anyMatch(cultivo -> cultivo.getNome().equalsIgnoreCase(nome));
        if (duplicado) {
            return Map.of("erro", "Já existe um cultivo cadastrado com esse nome.");
        }

        Map<String, Object> cultivo = new LinkedHashMap<>();
        cultivo.put("nome", nome);
        cultivo.put("tipo", tipo);
        faixas.forEach(cultivo::put);
        cultivo.put("habilitada", false);
        Map<String, Object> proposta = new LinkedHashMap<>();
        proposta.put("cultivo", cultivo);
        proposta.put("origem", valoresDoUsuario ? "valores informados por você" : "valores encontrados nas fontes");
        proposta.put("fontes", valoresDeFonte ? fontesDoCultivo : List.of());
        return Map.of("cadastroPendente", proposta);
    }

    private boolean buscaCorrespondeAoCultivo(String termo, String nome) {
        String termoNormalizado = normalizarTexto(termo);
        String nomeNormalizado = normalizarTexto(nome);
        return !termoNormalizado.isBlank()
                && !nomeNormalizado.isBlank()
                && java.util.Arrays.stream(nomeNormalizado.split("\\s+"))
                        .filter(palavra -> palavra.length() > 2)
                        .anyMatch(termoNormalizado::contains);
    }

    private Map<String, Object> mapaComoTextoObjeto(Map<?, ?> mapa) {
        Map<String, Object> convertido = new LinkedHashMap<>();
        mapa.forEach((chave, valor) -> convertido.put(String.valueOf(chave), valor));
        return convertido;
    }

    private String normalizarTexto(String texto) {
        return Normalizer.normalize(texto == null ? "" : texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
    }

    private boolean contémNumero(String texto, double esperado) {
        if (texto == null || texto.isBlank()) {
            return false;
        }
        Matcher matcher = NUMERO_PATTERN.matcher(texto);
        while (matcher.find()) {
            try {
                double encontrado = Double.parseDouble(matcher.group().replace(',', '.'));
                if (Math.abs(encontrado - esperado) < 0.0001) {
                    return true;
                }
            } catch (NumberFormatException ignored) {
                // Ignore non-numeric fragments matched in free-form source text.
            }
        }
        return false;
    }

    private void registrarResultadoFerramenta(
            String nome,
            Map<String, Object> resultado,
            List<Map<String, String>> fontesExternas) {
        if (!"buscar_fontes_cultivo".equals(nome)) {
            return;
        }
        Object fontes = resultado.get("fontes");
        if (fontes instanceof List<?> lista) {
            for (Object fonte : lista) {
                if (fonte instanceof Map<?, ?> mapa) {
                    Map<String, String> fonteTexto = new LinkedHashMap<>();
                    mapa.forEach((chave, valor) -> fonteTexto.put(
                            String.valueOf(chave), String.valueOf(valor)));
                    fontesExternas.add(fonteTexto);
                }
            }
        }
    }

    private Map<String, Object> gerarLinkRelatorio(JsonNode argumentos) {
        String tabela = argumentos.path("tabela").asText("sensor_data").toLowerCase(Locale.ROOT);
        if (!Set.of("sensor_data", "alertas", "relatorio_diario").contains(tabela)) {
            throw new IllegalArgumentException("Tabela não permitida para exportação.");
        }
        LocalDate dataInicio = dataObrigatoria(argumentos, "inicio");
        LocalDate dataFim = dataObrigatoria(argumentos, "fim");
        if (dataFim.isBefore(dataInicio)) {
            throw new IllegalArgumentException("A data final deve ser igual ou posterior à inicial.");
        }
        if (dataFim.isAfter(dataInicio.plusDays(30))) {
            throw new IllegalArgumentException("O intervalo máximo para exportação é de 31 dias.");
        }
        String inicio = dataInicio.toString();
        String fim = dataFim.toString();
        String formato = argumentos.path("formato").asText("").toLowerCase(Locale.ROOT);
        if (!Set.of("csv", "pdf").contains(formato)) {
            throw new IllegalArgumentException("Escolha o formato CSV ou PDF.");
        }

        String parametros = "tabela=" + codificarUrl(tabela)
                + "&inicio=" + codificarUrl(inicio)
                + "&fim=" + codificarUrl(fim)
                + "&formato=" + codificarUrl(formato);
        String nome = "estufa_" + tabela + "_" + inicio + "_a_" + fim + "." + formato;
        return Map.of(
                "mensagem", "Arquivo pronto para download.",
                "arquivoUrl", "/api/ia/relatorio?" + parametros,
                "arquivoNome", nome);
    }

    private LocalDate dataObrigatoria(JsonNode argumentos, String campo) {
        String valor = argumentos.path(campo).asText("");
        if (valor.isBlank()) {
            throw new IllegalArgumentException("Informe o campo de data " + campo + ".");
        }
        try {
            return LocalDate.parse(valor);
        } catch (DateTimeParseException erro) {
            throw new IllegalArgumentException("Use datas no formato AAAA-MM-DD.", erro);
        }
    }

    private LocalDate dataOpcional(JsonNode argumentos, String campo) {
        String valor = argumentos.path(campo).asText("");
        return valor.isBlank() ? null : dataObrigatoria(argumentos, campo);
    }

    private String codificarUrl(String valor) {
        return URLEncoder.encode(valor, StandardCharsets.UTF_8);
    }

    private void validarResposta(JsonNode resposta) {
        if (resposta.has("error")) {
            throw new IllegalStateException(resposta.path("error").path("message")
                    .asText("O provedor de IA recusou a solicitação."));
        }
        }

    private String get(String url) throws Exception {
        HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(10))
                .header("Accept", "application/json")
                .header("User-Agent", "EstufaSmart/1.0 (cultivation source lookup)")
                .GET()
                .build();
        HttpResponse<String> resposta = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (resposta.statusCode() < 200 || resposta.statusCode() >= 300) {
            throw new IllegalStateException("A busca externa respondeu HTTP " + resposta.statusCode() + ".");
        }
        return resposta.body();
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