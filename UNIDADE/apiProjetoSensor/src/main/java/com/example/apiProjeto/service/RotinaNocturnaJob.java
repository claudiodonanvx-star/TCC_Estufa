package com.example.apiProjeto.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Job noturno de manutenção:
 *   00:10 → consolida D-1 na tabela relatorio_diario
 *   00:20 → remove leituras brutas com mais de 90 dias
 */
@Component
public class RotinaNocturnaJob {

    private static final Logger log = LoggerFactory.getLogger(RotinaNocturnaJob.class);

    private static final int RETENCAO_DIAS = 90;

    @Autowired
    private ConsolidacaoService consolidacaoService;

    /** Executa toda noite às 00:10 para consolidar o dia anterior. */
    @Scheduled(cron = "0 10 0 * * *")
    public void consolidarD1() {
        log.info("[JOB] Iniciando consolidação D-1...");
        try {
            String resultado = consolidacaoService.consolidarD1();
            log.info("[JOB] {}", resultado);
        } catch (Exception e) {
            log.error("[JOB] Erro na consolidação D-1: {}", e.getMessage(), e);
        }
    }

    /** Executa toda noite às 00:20 para limpar dados brutos antigos. */
    @Scheduled(cron = "0 20 0 * * *")
    public void limparDadosAntigos() {
        log.info("[JOB] Iniciando limpeza de dados brutos com mais de {} dias...", RETENCAO_DIAS);
        try {
            String resultado = consolidacaoService.limparAntigos(RETENCAO_DIAS);
            log.info("[JOB] {}", resultado);
        } catch (Exception e) {
            log.error("[JOB] Erro na limpeza: {}", e.getMessage(), e);
        }
    }
}
