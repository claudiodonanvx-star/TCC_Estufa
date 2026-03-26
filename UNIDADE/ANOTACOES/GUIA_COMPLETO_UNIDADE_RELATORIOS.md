# Anotacoes tecnicas - UNIDADE (produto no cliente)

## 1. Escopo
- Contexto: parte UNIDADE do TCC (produto instalado no cliente).
- Fora do escopo deste arquivo: sistema EMPRESA (comercial, contratos, faturamento).
- Objetivo: organizar decisoes tecnicas sobre coleta, consolidacao, relatorios e manutencao de banco.

## 2. Fronteira UNIDADE x EMPRESA
- UNIDADE:
  - telemetria de sensores;
  - eventos de rele;
  - regras de automacao;
  - relatorios tecnicos de operacao.
- EMPRESA:
  - gestao comercial e operacao interna;
  - indicadores consolidados recebidos da UNIDADE;
  - sem dependencia de dados brutos de 20s.

Regra fixa:
- relatorio tecnico nasce na UNIDADE;
- EMPRESA consome resumo consolidado quando necessario.

## 3. Stack definida
- API: Java + Spring Boot.
- Banco: MySQL.
- Frontend: HTML/CSS/JS.
- Sem React/Vite como obrigacao de entrega.

## 4. Problema tecnico
- Coleta em alta frequencia gera volume alto.
- Relatorio nao pode depender da tabela bruta em consultas longas.
- Necessidade de historico por dia, semana, mes e ano.
- Necessidade de contabilizar:
  - oscilacoes ambientais;
  - acionamentos automaticos;
  - acionamentos forcados.

## 5. Modelo de dados recomendado

### 5.1 Tabela bruta
Nome sugerido: sensor_data_raw

Campos minimos:
- id (PK)
- unidade_id
- coletado_em (datetime)
- temperatura
- umidade_ar
- umidade_solo (nullable)
- significado/status (opcional)

Funcao:
- trilha completa de leitura;
- auditoria;
- base para consolidacao.

### 5.2 Tabela de eventos de rele
Nome sugerido: relay_event

Campos minimos:
- id (PK)
- unidade_id
- evento_em (datetime)
- equipamento
- acao (LIGAR, DESLIGAR)
- modo_acionamento (AUTOMATICO, FORCADO)
- motivo
- usuario_id (nullable)

Funcao:
- rastrear atuacao;
- contar automatico vs forcado;
- gerar indicadores de operacao.

### 5.3 Tabela consolidada diaria
Nome sugerido: unidade_relatorio_diario

Regra:
- 1 linha por dia por unidade.

Campos minimos:
- id (PK)
- unidade_id
- data_ref (date)
- temp_media, temp_min, temp_max
- umid_media, umid_min, umid_max
- umid_solo_media, umid_solo_min, umid_solo_max (quando aplicavel)
- qtd_osc_temp
- qtd_osc_umid
- qtd_acion_auto
- qtd_acion_forcado
- atualizado_em

Indice obrigatorio:
- unique(unidade_id, data_ref)

## 6. Regra para semana/mes/ano
- Nao criar estrutura por "segunda, terca, quarta".
- Armazenar data_ref normal (YYYY-MM-DD).
- Semana, mes e ano sao agregacoes de consulta.

Padrao:
- Diario: origem na unidade_relatorio_diario.
- Semanal: aggregate sobre diaria.
- Mensal: aggregate sobre diaria.
- Anual: aggregate sobre diaria.

## 7. Definicoes de indicador
- Oscilacao de temperatura: variacao acima de 3.0 C em 10 minutos.
- Oscilacao de umidade: variacao acima de 8.0 pontos em 10 minutos.
- Acionamento forcado: comando humano (painel/app).
- Acionamento automatico: comando por regra de controle.

Observacao:
- limiares podem mudar, mas precisam ser oficializados no TCC.

## 8. Decisao operacional (API x script)
Decisao fechada:
- API faz regra de negocio e consolidacao.
- Script faz orquestracao agendada e manutencao.

Distribuicao:
- API:
  - recebe leituras;
  - registra eventos de rele;
  - executa consolidacao (ou procedure SQL versionada pelo projeto);
  - expoe endpoints de relatorio.
- Script agendado:
  - dispara rotinas em horario definido;
  - faz limpeza de dados antigos;
  - executa manutencao;
  - gera log de execucao.

Validacao de execucao (regra de bloqueio):
- script valida se pode iniciar a rotina noturna;
- API valida endpoints de manutencao/consolidacao manual;
- objetivo do bloqueio: abortar job duplicado;
- ingestao de leituras da API permanece ativa.

Implementacao recomendada de lock:
- tabela de controle de execucao (job_lock) com status RUNNING, DONE, FAILED;
- script tenta adquirir lock no inicio;
- se lock ativo existir, script encerra a propria rotina;
- ao finalizar, script libera/atualiza lock;
- lock com timeout para recuperacao automatica em caso de falha.

## 9. API deve parar para evitar conflito?
Decisao recomendada:
- nao parar API.

Motivo:
- consolidacao processa somente dia fechado (D-1);
- API registra dados do dia atual;
- sem sobreposicao de periodo, sem necessidade de interrupcao.

Alternativa de emergencia:
- parada X-Y apenas se houver bloqueio operacional real.
- nao usar como estrategia principal.

Regra complementar:
- nao abortar acao de ingestao da API;
- abortar apenas execucao concorrente de rotina de manutencao/consolidacao.

## 10. Onde remover registros antigos
- Remocao recorrente: script no agendador de tarefas.
- Remocao pontual humana: opcional via endpoint admin restrito.
- Padrao para entrega: centralizar remocao no script agendado.

## 11. Janela diaria sugerida
- 00:10: consolidar D-1 (upsert na diaria).
- 00:20: apagar bruta antiga em lotes.
- 00:40: manutencao de tabela/indice (quando necessario).
- 00:50: registrar status final e metricas da execucao.

## 12. Politica de retencao
- Bruta: manter 60 a 90 dias (ajustar por capacidade).
- Diaria: manter longo prazo (anos).
- Eventos de rele: manter longo prazo (anos), com revisao anual.

## 13. Performance e integridade
Indices minimos:
- sensor_data_raw:
  - (unidade_id, coletado_em)
  - (coletado_em)
- relay_event:
  - (unidade_id, evento_em)
  - (modo_acionamento, evento_em)
- unidade_relatorio_diario:
  - unique(unidade_id, data_ref)

Praticas:
- delete em lote por faixa de tempo;
- evitar delete massivo unico em horario de pico;
- upsert na diaria para idempotencia;
- logs de inicio/fim e contagem de linhas processadas.

## 14. Observacao sobre VACUUM e REINDEX
- VACUUM/REINDEX sao termos tipicos de PostgreSQL.
- Ambiente atual mapeado: MySQL.
- No MySQL:
  - foco em indice correto;
  - limpeza em lote;
  - manutencao pontual (ex.: OPTIMIZE TABLE quando necessario, nao rotina cega diaria).

## 15. Endpoints de relatorio (referencia)
- GET /api/relatorios/diario?unidadeId=1&inicio=2026-03-01&fim=2026-03-31
- GET /api/relatorios/semanal?unidadeId=1&inicio=2026-01-01&fim=2026-03-31
- GET /api/relatorios/mensal?unidadeId=1&inicio=2025-01-01&fim=2026-12-31
- GET /api/relatorios/anual?unidadeId=1
- GET /api/relatorios/eventos-rele?unidadeId=1&inicio=...&fim=...&modo=FORCADO
- GET /api/relatorios/export/csv?tipo=diario&unidadeId=1&inicio=...&fim=...

## 16. Fluxo operacional alvo
1. Sensor envia leitura a cada 20s.
2. API valida payload e salva leitura bruta.
3. API registra evento de rele quando houver atuacao.
4. Job noturno consolida D-1 na diaria com upsert.
5. Job noturno remove dados brutos fora da janela de retencao.
6. Dashboard consome principalmente dados consolidados.

## 17. Checklist de implementacao
- [ ] Garantir coluna de data/hora confiavel em toda leitura.
- [ ] Garantir registro de evento de rele com modo automatico/forcado.
- [ ] Criar tabela diaria com unique(unidade_id, data_ref).
- [ ] Implementar consolidacao D-1 idempotente.
- [ ] Implementar limpeza por lote da tabela bruta.
- [ ] Expor endpoint diario/semanal/mensal/anual.
- [ ] Expor endpoint de eventos de rele.
- [ ] Expor exportacao CSV.
- [ ] Configurar agendador e log de rotinas.

## 18. Checklist de validacao para banca
- [ ] Historico diario coerente com amostras brutas.
- [ ] Quantidade de acionamentos forcados rastreavel.
- [ ] Quantidade de acionamentos automaticos rastreavel.
- [ ] Indicador de oscilacao com regra formal documentada.
- [ ] Tempo de resposta aceitavel em consultas de relatorio.
- [ ] Evidencias salvas (prints, logs, extratos CSV).

## 19. Riscos conhecidos
- Mistura indevida entre dados de UNIDADE e EMPRESA.
- Crescimento excessivo sem politica de retencao.
- Falta de regra formal de oscilacao.
- Dependencia da tabela bruta para consultas historicas longas.
- Ausencia de log nas rotinas agendadas.

Mitigacoes:
- fronteira de responsabilidade;
- consolidacao diaria;
- retencao + indice;
- observabilidade da rotina noturna.

## 20. Decisoes atuais consolidadas
- Stack mantida: Spring + MySQL + HTML/CSS/JS.
- API permanece ativa 24h; sem parada programada como padrao.
- Script agendado executa consolidacao, limpeza e manutencao.
- Remocao recorrente de registros antigos ocorre via script.
- Relatorios de periodo derivam da camada diaria consolidada.
