USE cl202195;

INSERT INTO emp_clientes (razao_social, nome_fantasia, cnpj, segmento, cidade, estado, contato_nome, contato_email, ativo, criado_em)
VALUES
('Flora Vale Produções Agrícolas LTDA', 'Flora Vale', '11.111.111/0001-11', 'Floricultura', 'Holambra', 'SP', 'Juliana Ramos', 'juliana@floravale.com.br', TRUE, NOW()),
('Horti Prime Cultivos SA', 'Horti Prime', '22.222.222/0001-22', 'Horticultura', 'Campinas', 'SP', 'Carlos Nogueira', 'carlos@hortiprime.com.br', TRUE, NOW()),
('Verde Sul Estufas LTDA', 'Verde Sul', '33.333.333/0001-33', 'Vegetais Folhosos', 'Curitiba', 'PR', 'Fernanda Luz', 'fernanda@verdesul.com.br', TRUE, NOW())
ON DUPLICATE KEY UPDATE
razao_social = VALUES(razao_social),
nome_fantasia = VALUES(nome_fantasia),
segmento = VALUES(segmento),
cidade = VALUES(cidade),
estado = VALUES(estado),
contato_nome = VALUES(contato_nome),
contato_email = VALUES(contato_email),
ativo = VALUES(ativo);

INSERT INTO emp_leads (nome_contato, empresa, email, telefone, origem, status, valor_estimado, proximo_contato_em, observacao, criado_em)
VALUES
('Marcelo Andrade', 'Sítio Aurora', 'marcelo@sitioaurora.com', '(19) 98888-1001', 'Indicação', 'NOVO', 12000.00, DATE_ADD(CURDATE(), INTERVAL 4 DAY), 'Interesse no plano básico para 2 estufas', NOW()),
('Patrícia Leal', 'Vale Verde Agro', 'patricia@valeverde.com', '(11) 97777-2211', 'Instagram', 'QUALIFICADO', 25000.00, DATE_ADD(CURDATE(), INTERVAL 7 DAY), 'Solicitou proposta com sensor de pH e CO2', NOW()),
('Rafael Duarte', 'Agro Sul', 'rafael@agrosul.com', '(41) 96666-3312', 'Site', 'PROPOSTA', 42000.00, DATE_ADD(CURDATE(), INTERVAL 2 DAY), 'Negociação em andamento para plano premium', NOW());

INSERT INTO emp_contratos (cliente_id, plano, status, valor_mensal, inicio_em, fim_em, renovacao_automatica, criado_em)
VALUES
(1, 'BASICO', 'ATIVO', 1490.00, DATE_SUB(CURDATE(), INTERVAL 220 DAY), DATE_ADD(CURDATE(), INTERVAL 45 DAY), FALSE, NOW()),
(2, 'MEDIO', 'ATIVO', 2890.00, DATE_SUB(CURDATE(), INTERVAL 150 DAY), DATE_ADD(CURDATE(), INTERVAL 28 DAY), TRUE, NOW()),
(3, 'PREMIUM', 'TESTE', 4590.00, DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY), FALSE, NOW());

INSERT INTO emp_unidades (nome_unidade, cidade, estado, quantidade_estufas, ativa, ultima_sincronizacao, criado_em)
VALUES
('Unidade Flora Vale - Setor A', 'Holambra', 'SP', 3, TRUE, NOW(), NOW()),
('Unidade Horti Prime Central', 'Campinas', 'SP', 5, TRUE, NOW(), NOW()),
('Unidade Horti Prime Norte', 'Paulínia', 'SP', 2, TRUE, NOW(), NOW()),
('Unidade Verde Sul Piloto', 'Curitiba', 'PR', 1, TRUE, NOW(), NOW());

INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em)
VALUES
(1, 1, DATE_SUB(CURDATE(), INTERVAL 220 DAY), NULL, TRUE, NOW()),
(2, 2, DATE_SUB(CURDATE(), INTERVAL 150 DAY), NULL, TRUE, NOW()),
(2, 3, DATE_SUB(CURDATE(), INTERVAL 120 DAY), NULL, TRUE, NOW()),
(3, 4, DATE_SUB(CURDATE(), INTERVAL 20 DAY), NULL, TRUE, NOW());

INSERT INTO emp_atividades (unidade_id, titulo, descricao, prioridade, responsavel, prazo_em, concluida, criado_em)
VALUES
(1, 'Calibrar sensor de pH', 'Ajustar calibração da sonda após troca de solução.', 'ALTA', 'Henrique Lima', DATE_ADD(CURDATE(), INTERVAL 3 DAY), FALSE, NOW()),
(2, 'Treinamento de equipe local', 'Treinamento de uso do painel e leitura de alertas.', 'MEDIA', 'Dani Souza', DATE_ADD(CURDATE(), INTERVAL 6 DAY), FALSE, NOW()),
(3, 'Instalar relé de aquecimento', 'Conectar módulo no quadro e validar acionamento.', 'CRITICA', 'Cláudio Donan', DATE_ADD(CURDATE(), INTERVAL 1 DAY), FALSE, NOW()),
(4, 'Checklist de startup', 'Validar conectividade da unidade piloto.', 'BAIXA', 'Evelin Moraes', DATE_ADD(CURDATE(), INTERVAL 8 DAY), FALSE, NOW());

INSERT INTO emp_usuarios (nome, email, login, senha_hash, perfil, gerente, ativo, criado_em)
VALUES
('Administrador Geral', 'admin@estufasmart.com.br', 'admin', 'admin123', 'ADMIN', TRUE, TRUE, NOW()),
('Gerente Operacional', 'gerente@estufasmart.com.br', 'gerente', 'gerente123', 'GERENTE', TRUE, TRUE, NOW()),
('Analista Comercial', 'analista@estufasmart.com.br', 'analista', 'analista123', 'ANALISTA', FALSE, TRUE, NOW()),
('Operador Campo', 'operador@estufasmart.com.br', 'operador', 'operador123', 'OPERADOR', FALSE, TRUE, NOW())
ON DUPLICATE KEY UPDATE nome = VALUES(nome), senha_hash = VALUES(senha_hash), perfil = VALUES(perfil), gerente = VALUES(gerente), ativo = VALUES(ativo);
