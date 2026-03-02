USE cl202195;

-- 1) Distribuição de leads por status
SELECT status, COUNT(*) AS total
FROM emp_leads
GROUP BY status
ORDER BY total DESC;

-- 2) Ticket estimado por estágio de lead
SELECT status, ROUND(AVG(valor_estimado), 2) AS ticket_medio, ROUND(SUM(valor_estimado), 2) AS pipeline_total
FROM emp_leads
GROUP BY status;

-- 3) Receita recorrente mensal (MRR) apenas contratos ativos
SELECT ROUND(SUM(valor_mensal), 2) AS mrr_ativo
FROM emp_contratos
WHERE status = 'ATIVO';

-- 4) Receita por plano
SELECT plano, COUNT(*) AS qtd_contratos, ROUND(SUM(valor_mensal), 2) AS receita_mensal
FROM emp_contratos
WHERE status IN ('ATIVO', 'TESTE')
GROUP BY plano;

-- 5) Contratos próximos de renovação (30 dias)
SELECT c.id, cli.nome_fantasia AS cliente, c.plano, c.fim_em, c.valor_mensal
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
WHERE c.status = 'ATIVO'
  AND c.fim_em BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY c.fim_em;

-- 6) Unidades por cliente
SELECT cli.nome_fantasia AS cliente, COUNT(u.id) AS total_unidades, SUM(u.quantidade_estufas) AS total_estufas
FROM emp_clientes cli
JOIN emp_contratos c ON c.cliente_id = cli.id
JOIN emp_contrato_unidades cu ON cu.contrato_id = c.id AND cu.ativo = TRUE
JOIN emp_unidades u ON u.id = cu.unidade_id
GROUP BY cli.id, cli.nome_fantasia
ORDER BY total_estufas DESC;

-- 7) Atividades por prioridade e status
SELECT prioridade, concluida, COUNT(*) AS total
FROM emp_atividades
GROUP BY prioridade, concluida
ORDER BY FIELD(prioridade, 'CRITICA', 'ALTA', 'MEDIA', 'BAIXA'), concluida;

-- 8) Atividades atrasadas
SELECT a.id, u.nome_unidade, a.titulo, a.prioridade, a.prazo_em, a.responsavel
FROM emp_atividades a
JOIN emp_unidades u ON u.id = a.unidade_id
WHERE a.concluida = FALSE
  AND a.prazo_em < CURDATE()
ORDER BY a.prazo_em ASC;

-- 9) Top 5 clientes por valor mensal contratado
SELECT cli.nome_fantasia AS cliente, ROUND(SUM(c.valor_mensal), 2) AS total_mensal
FROM emp_clientes cli
JOIN emp_contratos c ON c.cliente_id = cli.id
WHERE c.status IN ('ATIVO', 'TESTE')
GROUP BY cli.id, cli.nome_fantasia
ORDER BY total_mensal DESC
LIMIT 5;

-- 10) Sanidade de chaves (linhas órfãs)
SELECT 'contratos_sem_cliente' AS regra, COUNT(*) AS total
FROM emp_contratos c
LEFT JOIN emp_clientes cli ON cli.id = c.cliente_id
WHERE cli.id IS NULL
UNION ALL
SELECT 'vinculos_sem_contrato' AS regra, COUNT(*) AS total
FROM emp_contrato_unidades cu
LEFT JOIN emp_contratos c ON c.id = cu.contrato_id
WHERE c.id IS NULL
UNION ALL
SELECT 'atividades_sem_unidade' AS regra, COUNT(*) AS total
FROM emp_atividades a
LEFT JOIN emp_unidades u ON u.id = a.unidade_id
WHERE u.id IS NULL
UNION ALL
SELECT 'vinculos_sem_unidade' AS regra, COUNT(*) AS total
FROM emp_contrato_unidades cu
LEFT JOIN emp_unidades u ON u.id = cu.unidade_id
WHERE u.id IS NULL;

-- 11) Usuários por perfil
SELECT perfil, gerente, ativo, COUNT(*) AS total
FROM emp_usuarios
GROUP BY perfil, gerente, ativo
ORDER BY FIELD(perfil, 'ADMIN', 'GERENTE', 'ANALISTA', 'OPERADOR');

-- 12) Unidades multi-contrato (simulação de escalabilidade)
SELECT u.nome_unidade, COUNT(cu.id) AS qtd_contratos_vinculados
FROM emp_unidades u
JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id AND cu.ativo = TRUE
GROUP BY u.id, u.nome_unidade
HAVING COUNT(cu.id) > 1
ORDER BY qtd_contratos_vinculados DESC;
