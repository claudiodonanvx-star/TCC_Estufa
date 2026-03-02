USE cl202195;

SELECT 'LEADS_ABERTOS' AS metrica, COUNT(*) AS total
FROM emp_leads
WHERE status IN ('NOVO', 'QUALIFICADO', 'PROPOSTA');

SELECT 'CLIENTES_ATIVOS' AS metrica, COUNT(*) AS total
FROM emp_clientes
WHERE ativo = TRUE;

SELECT 'CONTRATOS_ATIVOS' AS metrica, COUNT(*) AS total
FROM emp_contratos
WHERE status = 'ATIVO';

SELECT 'UNIDADES_ATIVAS' AS metrica, COUNT(*) AS total
FROM emp_unidades
WHERE ativa = TRUE;

SELECT 'ATIVIDADES_PENDENTES' AS metrica, COUNT(*) AS total
FROM emp_atividades
WHERE concluida = FALSE;

SELECT
  c.id AS contrato_id,
  cli.nome_fantasia AS cliente,
  c.plano,
  c.status,
  c.fim_em,
  c.valor_mensal
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
ORDER BY c.fim_em ASC;

SELECT
  a.id AS atividade_id,
  u.nome_unidade,
  a.titulo,
  a.prioridade,
  a.prazo_em,
  a.concluida
FROM emp_atividades a
JOIN emp_unidades u ON u.id = a.unidade_id
ORDER BY a.prazo_em ASC;
