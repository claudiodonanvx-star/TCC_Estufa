USE cl202195;

-- Simula evolução de pipeline comercial
UPDATE emp_leads
SET status = 'QUALIFICADO'
WHERE status = 'NOVO'
  AND proximo_contato_em <= DATE_ADD(CURDATE(), INTERVAL 5 DAY);

UPDATE emp_leads
SET status = 'PROPOSTA'
WHERE status = 'QUALIFICADO'
  AND valor_estimado >= 25000;

UPDATE emp_leads
SET status = 'FECHADO'
WHERE status = 'PROPOSTA'
  AND valor_estimado >= 45000;

-- Simula atualização de sincronização de unidades
UPDATE emp_unidades
SET ultima_sincronizacao = NOW()
WHERE ativa = TRUE;

-- Simula avanço de atividades (conclusão parcial)
UPDATE emp_atividades
SET concluida = TRUE
WHERE prioridade IN ('BAIXA', 'MEDIA')
  AND prazo_em <= DATE_ADD(CURDATE(), INTERVAL 6 DAY);

-- Simula encerramento de contrato de teste mais antigo
UPDATE emp_contratos
SET status = 'ATIVO'
WHERE status = 'TESTE'
  AND inicio_em <= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
