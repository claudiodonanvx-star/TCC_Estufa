package com.example.apiProjeto.service;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.stereotype.Service;

@Service
public class ArquivoRelatorioService {

    private static final int LINHAS_POR_PAGINA = 52;

    private final ConsultaBancoLeituraService consultaBancoLeituraService;

    public ArquivoRelatorioService(ConsultaBancoLeituraService consultaBancoLeituraService) {
        this.consultaBancoLeituraService = consultaBancoLeituraService;
    }

    public ArquivoGerado gerar(String tabela, LocalDate inicio, LocalDate fim, String formato) {
        String formatoNormalizado = formato == null ? "" : formato.toLowerCase(Locale.ROOT);
        if (!formatoNormalizado.equals("csv") && !formatoNormalizado.equals("pdf")) {
            throw new IllegalArgumentException("O formato deve ser CSV ou PDF.");
        }

        List<Map<String, Object>> registros =
                consultaBancoLeituraService.consultarParaExportacao(tabela, inicio, fim);
        String nome = "estufa_" + tabela + "_" + inicio + "_a_" + fim + "." + formatoNormalizado;
        byte[] conteudo = formatoNormalizado.equals("csv")
                ? gerarCsv(registros)
                : gerarPdf(tabela, inicio, fim, registros);
        String tipoMime = formatoNormalizado.equals("csv")
                ? "text/csv;charset=UTF-8"
                : "application/pdf";
        return new ArquivoGerado(nome, tipoMime, conteudo);
    }

    private byte[] gerarCsv(List<Map<String, Object>> registros) {
        StringBuilder csv = new StringBuilder("\uFEFF");
        if (!registros.isEmpty()) {
            List<String> colunas = new ArrayList<>(registros.get(0).keySet());
            csv.append(String.join(";", colunas.stream().map(this::escaparCsv).toList())).append("\r\n");
            for (Map<String, Object> registro : registros) {
                csv.append(String.join(";", colunas.stream()
                        .map(coluna -> escaparCsv(registro.get(coluna)))
                        .toList())).append("\r\n");
            }
        } else {
            csv.append("sem_dados\r\n");
        }
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    private String escaparCsv(Object valor) {
        String texto = valor == null ? "" : valor.toString();
        return "\"" + texto.replace("\"", "\"\"") + "\"";
    }

    private byte[] gerarPdf(
            String tabela,
            LocalDate inicio,
            LocalDate fim,
            List<Map<String, Object>> registros) {
        List<String> linhas = new ArrayList<>();
        linhas.add("Relatorio Estufa Smart");
        linhas.add("Tabela: " + tabela + " | Periodo: " + inicio + " ate " + fim);
        linhas.add("Registros: " + registros.size());
        linhas.add("");

        if (registros.isEmpty()) {
            linhas.add("Nenhum registro encontrado no periodo.");
        } else {
            for (Map<String, Object> registro : registros) {
                String linha = registro.entrySet().stream()
                        .map(campo -> campo.getKey() + ": " + campo.getValue())
                        .reduce((a, b) -> a + " | " + b)
                        .orElse("");
                quebrarLinha(linhas, linha);
            }
        }

        List<List<String>> paginas = new ArrayList<>();
        for (int inicioPagina = 0; inicioPagina < linhas.size(); inicioPagina += LINHAS_POR_PAGINA) {
            paginas.add(linhas.subList(
                    inicioPagina,
                    Math.min(inicioPagina + LINHAS_POR_PAGINA, linhas.size())));
        }
        return escreverPdf(paginas);
    }

    private void quebrarLinha(List<String> destino, String linha) {
        String normalizada = paraAscii(linha);
        for (int inicio = 0; inicio < normalizada.length(); inicio += 110) {
            destino.add(normalizada.substring(inicio, Math.min(inicio + 110, normalizada.length())));
        }
    }

    private String paraAscii(String texto) {
        String semAcentos = Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return semAcentos.replaceAll("[^\\x20-\\x7E]", "?");
    }

    private byte[] escreverPdf(List<List<String>> paginas) {
        try {
            int objetoFonte = 3 + paginas.size() * 2;
            List<byte[]> objetos = new ArrayList<>();
            objetos.add(ascii("<< /Type /Catalog /Pages 2 0 R >>"));

            StringBuilder filhos = new StringBuilder();
            for (int indice = 0; indice < paginas.size(); indice++) {
                filhos.append(3 + indice * 2).append(" 0 R ");
            }
            objetos.add(ascii("<< /Type /Pages /Kids [" + filhos + "] /Count " + paginas.size() + " >>"));

            for (int indice = 0; indice < paginas.size(); indice++) {
                int objetoPagina = 3 + indice * 2;
                int objetoConteudo = objetoPagina + 1;
                objetos.add(ascii("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
                        + "/Resources << /Font << /F1 " + objetoFonte + " 0 R >> >> "
                        + "/Contents " + objetoConteudo + " 0 R >>"));
                byte[] conteudo = ascii(conteudoPagina(paginas.get(indice)));
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                stream.write(ascii("<< /Length " + conteudo.length + " >>\nstream\n"));
                stream.write(conteudo);
                stream.write(ascii("\nendstream"));
                objetos.add(stream.toByteArray());
            }
            objetos.add(ascii("<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>"));

            ByteArrayOutputStream pdf = new ByteArrayOutputStream();
            pdf.write(ascii("%PDF-1.4\n"));
            List<Integer> offsets = new ArrayList<>();
            offsets.add(0);
            for (int indice = 0; indice < objetos.size(); indice++) {
                offsets.add(pdf.size());
                pdf.write(ascii((indice + 1) + " 0 obj\n"));
                pdf.write(objetos.get(indice));
                pdf.write(ascii("\nendobj\n"));
            }

            int inicioXref = pdf.size();
            pdf.write(ascii("xref\n0 " + (objetos.size() + 1) + "\n"));
            pdf.write(ascii("0000000000 65535 f \n"));
            for (int indice = 1; indice < offsets.size(); indice++) {
                pdf.write(ascii(String.format(Locale.ROOT, "%010d 00000 n \n", offsets.get(indice))));
            }
            pdf.write(ascii("trailer\n<< /Size " + (objetos.size() + 1) + " /Root 1 0 R >>\n"));
            pdf.write(ascii("startxref\n" + inicioXref + "\n%%EOF"));
            return pdf.toByteArray();
        } catch (java.io.IOException erro) {
            throw new IllegalStateException("Não foi possível gerar o PDF.", erro);
        }
    }

    private String conteudoPagina(List<String> linhas) {
        StringBuilder conteudo = new StringBuilder("BT\n/F1 8 Tf\n36 756 Td\n");
        for (String linha : linhas) {
            conteudo.append('(')
                    .append(linha.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)"))
                    .append(") Tj\n0 -13 Td\n");
        }
        return conteudo.append("ET").toString();
    }

    private byte[] ascii(String texto) {
        return texto.getBytes(StandardCharsets.US_ASCII);
    }

    public record ArquivoGerado(String nome, String tipoMime, byte[] conteudo) {}
}
