USE cl202195;

INSERT INTO emp_clientes (razao_social, nome_fantasia, cnpj, segmento, cidade, estado, contato_nome, contato_email, ativo, criado_em)
VALUES
('Campo Alto Hortifruti LTDA', 'Campo Alto', '44.444.444/0001-44', 'Hortifruti', 'Atibaia', 'SP', 'Daniel Porto', 'daniel@campoalto.com.br', TRUE, NOW()),
('Serras Verdes Produção SA', 'Serras Verdes', '55.555.555/0001-55', 'Flores de Corte', 'Mogi das Cruzes', 'SP', 'Aline Farias', 'aline@serrasverdes.com.br', TRUE, NOW()),
('Raiz Forte Agroindustrial LTDA', 'Raiz Forte', '66.666.666/0001-66', 'Tomates', 'Jundiaí', 'SP', 'Luiz Esteves', 'luiz@raizforte.com.br', TRUE, NOW()),
('Vale do Sol Hidroponia LTDA', 'Vale do Sol', '77.777.777/0001-77', 'Hidroponia', 'Limeira', 'SP', 'Marina Costa', 'marina@valedosol.com.br', TRUE, NOW()),
('Aurora Rural Cooperativa', 'Coop Aurora', '88.888.888/0001-88', 'Cooperativa Agrícola', 'Americana', 'SP', 'Rita Freitas', 'rita@coopaurora.com.br', TRUE, NOW())
ON DUPLICATE KEY UPDATE nome_fantasia = VALUES(nome_fantasia), segmento = VALUES(segmento), cidade = VALUES(cidade), estado = VALUES(estado), contato_nome = VALUES(contato_nome), contato_email = VALUES(contato_email), ativo = VALUES(ativo);

INSERT INTO emp_leads (nome_contato, empresa, email, telefone, origem, status, valor_estimado, proximo_contato_em, observacao, criado_em)
VALUES
('Gustavo Maia', 'Fazenda Primavera', 'gustavo@primavera.com', '(19) 98880-0101', 'Feira Agro', 'NOVO', 18000.00, DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'Interesse em monitoramento inicial', NOW()),
('Bianca Neves', 'Estufas Bom Clima', 'bianca@bomclima.com', '(19) 98880-0102', 'Instagram', 'QUALIFICADO', 31000.00, DATE_ADD(CURDATE(), INTERVAL 6 DAY), 'Quer CO2 e umidade de solo', NOW()),
('João Peixoto', 'Sítio Aliança', 'joao@alianca.com', '(19) 98880-0103', 'Site', 'PROPOSTA', 47000.00, DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Proposta premium em revisão', NOW()),
('Larissa Pinto', 'Horta Bela Vista', 'larissa@belavista.com', '(19) 98880-0104', 'Indicação', 'NOVO', 14000.00, DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'Projeto para duas estufas', NOW()),
('Pedro Gomes', 'Flora Real', 'pedro@florareal.com', '(19) 98880-0105', 'Parceiro', 'QUALIFICADO', 26000.00, DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'Aguardando visita técnica', NOW()),
('Amanda Cezar', 'Campo Vivo', 'amanda@campovivo.com', '(19) 98880-0106', 'LinkedIn', 'NOVO', 19500.00, DATE_ADD(CURDATE(), INTERVAL 8 DAY), 'Quer integração com automação futura', NOW()),
('Rogério Simões', 'Verde Mais', 'rogerio@verdemais.com', '(19) 98880-0107', 'Google', 'PROPOSTA', 52000.00, DATE_ADD(CURDATE(), INTERVAL 3 DAY), 'Fase final de negociação', NOW()),
('Cíntia Lara', 'Agro Life', 'cintia@agrolife.com', '(19) 98880-0108', 'Feira Agro', 'NOVO', 23000.00, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Dúvidas sobre plano médio', NOW());

INSERT INTO emp_contratos (cliente_id, plano, status, valor_mensal, inicio_em, fim_em, renovacao_automatica, criado_em)
SELECT c.id, 'BASICO', 'ATIVO', 1590.00, DATE_SUB(CURDATE(), INTERVAL 90 DAY), DATE_ADD(CURDATE(), INTERVAL 40 DAY), TRUE, NOW()
FROM emp_clientes c
WHERE c.cnpj = '44.444.444/0001-44'
  AND NOT EXISTS (SELECT 1 FROM emp_contratos x WHERE x.cliente_id = c.id AND x.plano = 'BASICO' AND x.status IN ('ATIVO', 'TESTE'));

INSERT INTO emp_contratos (cliente_id, plano, status, valor_mensal, inicio_em, fim_em, renovacao_automatica, criado_em)
SELECT c.id, 'MEDIO', 'ATIVO', 3090.00, DATE_SUB(CURDATE(), INTERVAL 120 DAY), DATE_ADD(CURDATE(), INTERVAL 25 DAY), TRUE, NOW()
FROM emp_clientes c
WHERE c.cnpj = '55.555.555/0001-55'
  AND NOT EXISTS (SELECT 1 FROM emp_contratos x WHERE x.cliente_id = c.id AND x.plano = 'MEDIO' AND x.status IN ('ATIVO', 'TESTE'));

INSERT INTO emp_contratos (cliente_id, plano, status, valor_mensal, inicio_em, fim_em, renovacao_automatica, criado_em)
SELECT c.id, 'PREMIUM', 'ATIVO', 4890.00, DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_ADD(CURDATE(), INTERVAL 18 DAY), FALSE, NOW()
FROM emp_clientes c
WHERE c.cnpj = '66.666.666/0001-66'
  AND NOT EXISTS (SELECT 1 FROM emp_contratos x WHERE x.cliente_id = c.id AND x.plano = 'PREMIUM' AND x.status IN ('ATIVO', 'TESTE'));

INSERT INTO emp_contratos (cliente_id, plano, status, valor_mensal, inicio_em, fim_em, renovacao_automatica, criado_em)
SELECT c.id, 'MEDIO', 'TESTE', 2990.00, DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), FALSE, NOW()
FROM emp_clientes c
WHERE c.cnpj = '77.777.777/0001-77'
  AND NOT EXISTS (SELECT 1 FROM emp_contratos x WHERE x.cliente_id = c.id AND x.plano = 'MEDIO' AND x.status IN ('ATIVO', 'TESTE'));

INSERT INTO emp_contratos (cliente_id, plano, status, valor_mensal, inicio_em, fim_em, renovacao_automatica, criado_em)
SELECT c.id, 'BASICO', 'ATIVO', 1450.00, DATE_SUB(CURDATE(), INTERVAL 35 DAY), DATE_ADD(CURDATE(), INTERVAL 70 DAY), TRUE, NOW()
FROM emp_clientes c
WHERE c.cnpj = '88.888.888/0001-88'
  AND NOT EXISTS (SELECT 1 FROM emp_contratos x WHERE x.cliente_id = c.id AND x.plano = 'BASICO' AND x.status IN ('ATIVO', 'TESTE'));

INSERT INTO emp_unidades (nome_unidade, cidade, estado, quantidade_estufas, ativa, ultima_sincronizacao, criado_em)
SELECT 'Campo Alto - Unidade Leste', 'Atibaia', 'SP', 2, TRUE, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM emp_unidades u WHERE u.nome_unidade = 'Campo Alto - Unidade Leste');

INSERT INTO emp_unidades (nome_unidade, cidade, estado, quantidade_estufas, ativa, ultima_sincronizacao, criado_em)
SELECT 'Serras Verdes - Matriz', 'Mogi das Cruzes', 'SP', 4, TRUE, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM emp_unidades u WHERE u.nome_unidade = 'Serras Verdes - Matriz');

INSERT INTO emp_unidades (nome_unidade, cidade, estado, quantidade_estufas, ativa, ultima_sincronizacao, criado_em)
SELECT 'Raiz Forte - Polo 1', 'Jundiaí', 'SP', 6, TRUE, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM emp_unidades u WHERE u.nome_unidade = 'Raiz Forte - Polo 1');

INSERT INTO emp_unidades (nome_unidade, cidade, estado, quantidade_estufas, ativa, ultima_sincronizacao, criado_em)
SELECT 'Vale do Sol - Piloto', 'Limeira', 'SP', 1, TRUE, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM emp_unidades u WHERE u.nome_unidade = 'Vale do Sol - Piloto');

INSERT INTO emp_unidades (nome_unidade, cidade, estado, quantidade_estufas, ativa, ultima_sincronizacao, criado_em)
SELECT 'Coop Aurora - Bloco A', 'Americana', 'SP', 3, TRUE, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM emp_unidades u WHERE u.nome_unidade = 'Coop Aurora - Bloco A');

INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em)
SELECT c.id, u.id, DATE_SUB(CURDATE(), INTERVAL 90 DAY), NULL, TRUE, NOW()
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
JOIN emp_unidades u ON u.nome_unidade = 'Campo Alto - Unidade Leste'
WHERE cli.cnpj = '44.444.444/0001-44'
  AND NOT EXISTS (SELECT 1 FROM emp_contrato_unidades cu WHERE cu.contrato_id = c.id AND cu.unidade_id = u.id AND cu.ativo = TRUE);

INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em)
SELECT c.id, u.id, DATE_SUB(CURDATE(), INTERVAL 120 DAY), NULL, TRUE, NOW()
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
JOIN emp_unidades u ON u.nome_unidade = 'Serras Verdes - Matriz'
WHERE cli.cnpj = '55.555.555/0001-55'
  AND NOT EXISTS (SELECT 1 FROM emp_contrato_unidades cu WHERE cu.contrato_id = c.id AND cu.unidade_id = u.id AND cu.ativo = TRUE);

INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em)
SELECT c.id, u.id, DATE_SUB(CURDATE(), INTERVAL 60 DAY), NULL, TRUE, NOW()
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
JOIN emp_unidades u ON u.nome_unidade = 'Raiz Forte - Polo 1'
WHERE cli.cnpj = '66.666.666/0001-66'
  AND NOT EXISTS (SELECT 1 FROM emp_contrato_unidades cu WHERE cu.contrato_id = c.id AND cu.unidade_id = u.id AND cu.ativo = TRUE);

INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em)
SELECT c.id, u.id, DATE_SUB(CURDATE(), INTERVAL 10 DAY), NULL, TRUE, NOW()
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
JOIN emp_unidades u ON u.nome_unidade = 'Vale do Sol - Piloto'
WHERE cli.cnpj = '77.777.777/0001-77'
  AND NOT EXISTS (SELECT 1 FROM emp_contrato_unidades cu WHERE cu.contrato_id = c.id AND cu.unidade_id = u.id AND cu.ativo = TRUE);

INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em)
SELECT c.id, u.id, DATE_SUB(CURDATE(), INTERVAL 35 DAY), NULL, TRUE, NOW()
FROM emp_contratos c
JOIN emp_clientes cli ON cli.id = c.cliente_id
JOIN emp_unidades u ON u.nome_unidade = 'Coop Aurora - Bloco A'
WHERE cli.cnpj = '88.888.888/0001-88'
  AND NOT EXISTS (SELECT 1 FROM emp_contrato_unidades cu WHERE cu.contrato_id = c.id AND cu.unidade_id = u.id AND cu.ativo = TRUE);

INSERT INTO emp_atividades (unidade_id, titulo, descricao, prioridade, responsavel, prazo_em, concluida, criado_em)
SELECT u.id, 'Ajustar curva de irrigação', 'Revisar intervalos para reduzir consumo de água sem estresse hídrico.', 'ALTA', 'Cláudio Donan', DATE_ADD(CURDATE(), INTERVAL 2 DAY), FALSE, NOW()
FROM emp_unidades u
WHERE u.nome_unidade = 'Campo Alto - Unidade Leste'
  AND NOT EXISTS (SELECT 1 FROM emp_atividades a WHERE a.unidade_id = u.id AND a.titulo = 'Ajustar curva de irrigação');

INSERT INTO emp_atividades (unidade_id, titulo, descricao, prioridade, responsavel, prazo_em, concluida, criado_em)
SELECT u.id, 'Validar sensor de CO2', 'Conferir leitura com equipamento de referência e registrar calibração.', 'MEDIA', 'Dani Souza', DATE_ADD(CURDATE(), INTERVAL 5 DAY), FALSE, NOW()
FROM emp_unidades u
WHERE u.nome_unidade = 'Serras Verdes - Matriz'
  AND NOT EXISTS (SELECT 1 FROM emp_atividades a WHERE a.unidade_id = u.id AND a.titulo = 'Validar sensor de CO2');

INSERT INTO emp_atividades (unidade_id, titulo, descricao, prioridade, responsavel, prazo_em, concluida, criado_em)
SELECT u.id, 'Ativar automação de aquecimento', 'Testar acionamento no relé e confirmar faixa mínima.', 'CRITICA', 'Henrique Lima', DATE_ADD(CURDATE(), INTERVAL 1 DAY), FALSE, NOW()
FROM emp_unidades u
WHERE u.nome_unidade = 'Raiz Forte - Polo 1'
  AND NOT EXISTS (SELECT 1 FROM emp_atividades a WHERE a.unidade_id = u.id AND a.titulo = 'Ativar automação de aquecimento');

INSERT INTO emp_atividades (unidade_id, titulo, descricao, prioridade, responsavel, prazo_em, concluida, criado_em)
SELECT u.id, 'Treinamento de operação local', 'Capacitar equipe na leitura de alertas e uso do painel.', 'BAIXA', 'Evelin Moraes', DATE_ADD(CURDATE(), INTERVAL 9 DAY), FALSE, NOW()
FROM emp_unidades u
WHERE u.nome_unidade = 'Vale do Sol - Piloto'
  AND NOT EXISTS (SELECT 1 FROM emp_atividades a WHERE a.unidade_id = u.id AND a.titulo = 'Treinamento de operação local');

INSERT INTO emp_atividades (unidade_id, titulo, descricao, prioridade, responsavel, prazo_em, concluida, criado_em)
SELECT u.id, 'Checklist de expansão', 'Preparar expansão para mais uma estufa no bloco.', 'MEDIA', 'Heloísa Prado', DATE_ADD(CURDATE(), INTERVAL 12 DAY), FALSE, NOW()
FROM emp_unidades u
WHERE u.nome_unidade = 'Coop Aurora - Bloco A'
  AND NOT EXISTS (SELECT 1 FROM emp_atividades a WHERE a.unidade_id = u.id AND a.titulo = 'Checklist de expansão');

INSERT INTO emp_usuarios (nome, email, login, senha_hash, perfil, gerente, ativo, criado_em)
VALUES
('Gerente Comercial 01', 'gcom01@estufasmart.com.br', 'gcom01', 'senha123', 'GERENTE', TRUE, TRUE, NOW()),
('Gerente Operacional 02', 'gop02@estufasmart.com.br', 'gop02', 'senha123', 'GERENTE', TRUE, TRUE, NOW()),
('Analista Operações 01', 'ana01@estufasmart.com.br', 'ana01', 'senha123', 'ANALISTA', FALSE, TRUE, NOW()),
('Analista Operações 02', 'ana02@estufasmart.com.br', 'ana02', 'senha123', 'ANALISTA', FALSE, TRUE, NOW()),
('Operador Campo 01', 'op01@estufasmart.com.br', 'op01', 'senha123', 'OPERADOR', FALSE, TRUE, NOW()),
('Operador Campo 02', 'op02@estufasmart.com.br', 'op02', 'senha123', 'OPERADOR', FALSE, TRUE, NOW())
ON DUPLICATE KEY UPDATE nome = VALUES(nome), perfil = VALUES(perfil), gerente = VALUES(gerente), ativo = VALUES(ativo);
