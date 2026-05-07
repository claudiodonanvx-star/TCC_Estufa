package com.example.apiProjeto.controller;

import com.example.apiProjeto.model.RelatorioDiario;
import com.example.apiProjeto.repository.RelatorioDiarioRepository;
import com.example.apiProjeto.service.ConsolidacaoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/relatorios")
public class RelatoriosController {

    @Autowired
    private RelatorioDiarioRepository relatorioRepository;

    @Autowired
    private ConsolidacaoService consolidacaoService;

    /**
     * Lista relatórios diários entre duas datas.
     * GET /api/relatorios/diario?inicio=2026-05-01&fim=2026-05-31
     */
    @GetMapping("/diario")
    public ResponseEntity<List<RelatorioDiario>> getDiario(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {
        List<RelatorioDiario> result = relatorioRepository.findByDataRefBetweenOrderByDataRef(inicio, fim);
        return ResponseEntity.ok(result);
    }

    /**
     * Últimos 7 dias consolidados.
     * GET /api/relatorios/semanal
     */
    @GetMapping("/semanal")
    public ResponseEntity<List<RelatorioDiario>> getSemanal() {
        LocalDate fim = LocalDate.now().minusDays(1);
        LocalDate inicio = fim.minusDays(6);
        return ResponseEntity.ok(relatorioRepository.findByDataRefBetweenOrderByDataRef(inicio, fim));
    }

    /**
     * Últimos 30 dias consolidados.
     * GET /api/relatorios/mensal
     */
    @GetMapping("/mensal")
    public ResponseEntity<List<RelatorioDiario>> getMensal() {
        LocalDate fim = LocalDate.now().minusDays(1);
        LocalDate inicio = fim.minusDays(29);
        return ResponseEntity.ok(relatorioRepository.findByDataRefBetweenOrderByDataRef(inicio, fim));
    }

    /**
     * Últimos 365 dias consolidados.
     * GET /api/relatorios/anual
     */
    @GetMapping("/anual")
    public ResponseEntity<List<RelatorioDiario>> getAnual() {
        LocalDate fim = LocalDate.now().minusDays(1);
        LocalDate inicio = fim.minusDays(364);
        return ResponseEntity.ok(relatorioRepository.findByDataRefBetweenOrderByDataRef(inicio, fim));
    }

    /**
     * Exporta relatórios em formato CSV.
     * GET /api/relatorios/export/csv?tipo=mensal  (ou diario/semanal/anual)
     * Também aceita ?inicio=&fim= para intervalo customizado.
     */
    @GetMapping(value = "/export/csv", produces = "text/csv;charset=UTF-8")
    public ResponseEntity<String> exportCsv(
            @RequestParam(required = false) String tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {

        LocalDate fimEfetivo = fim != null ? fim : LocalDate.now().minusDays(1);
        LocalDate inicioEfetivo;

        if (inicio != null) {
            inicioEfetivo = inicio;
        } else if ("semanal".equalsIgnoreCase(tipo)) {
            inicioEfetivo = fimEfetivo.minusDays(6);
        } else if ("anual".equalsIgnoreCase(tipo)) {
            inicioEfetivo = fimEfetivo.minusDays(364);
        } else {
            inicioEfetivo = fimEfetivo.minusDays(29); // default mensal
        }

        List<RelatorioDiario> registros = relatorioRepository.findByDataRefBetweenOrderByDataRef(inicioEfetivo, fimEfetivo);

        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        pw.println("data,temp_media,temp_min,temp_max,umidade_media,umidade_min,umidade_max,solo_media,solo_min,solo_max,total_leituras");

        for (RelatorioDiario r : registros) {
            pw.printf(Locale.US, "%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d%n",
                    r.getDataRef(),
                    r.getTempMedia(), r.getTempMinima(), r.getTempMaxima(),
                    r.getUmidadeMedia(), r.getUmidadeMinima(), r.getUmidadeMaxima(),
                    r.getSoloMedia(), r.getSoloMinima(), r.getSoloMaxima(),
                    r.getTotalLeituras());
        }

        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=relatorio.csv")
                .body(sw.toString());
    }

    /**
     * Dispara consolidação manual de um dia específico (ou D-1 se não informado).
     * POST /api/relatorios/consolidar
     * Body (opcional): { "data": "2026-05-04" }
     */
    @PostMapping("/consolidar")
    public ResponseEntity<Map<String, String>> consolidar(@RequestBody(required = false) Map<String, String> body) {
        try {
            String resultado;
            if (body != null && body.containsKey("data")) {
                LocalDate data = LocalDate.parse(body.get("data"));
                resultado = consolidacaoService.consolidarDia(data);
            } else {
                resultado = consolidacaoService.consolidarD1();
            }
            return ResponseEntity.ok(Map.of("mensagem", resultado));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("mensagem", "Erro: " + e.getMessage()));
        }
    }

    /**
     * Dispara limpeza manual de dados brutos antigos.
     * POST /api/relatorios/limpar?dias=90
     */
    @PostMapping("/limpar")
    public ResponseEntity<Map<String, String>> limpar(
            @RequestParam(defaultValue = "90") int dias) {
        try {
            String resultado = consolidacaoService.limparAntigos(dias);
            return ResponseEntity.ok(Map.of("mensagem", resultado));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("mensagem", "Erro: " + e.getMessage()));
        }
    }
}
