USE cl202195;

INSERT INTO emp_usuarios (nome, email, login, senha_hash, perfil, gerente, ativo, criado_em)
VALUES
('Administrador Geral', 'admin@estufasmart.com.br', 'admin', 'admin123', 'ADMIN', TRUE, TRUE, NOW()),
('Gerente Operacional', 'gerente@estufasmart.com.br', 'gerente', 'gerente123', 'GERENTE', TRUE, TRUE, NOW()),
('Gerente Comercial', 'gerente.comercial@estufasmart.com.br', 'gercom', 'gercom123', 'GERENTE', TRUE, TRUE, NOW()),
('Analista Comercial 01', 'analista01@estufasmart.com.br', 'analista01', 'analista123', 'ANALISTA', FALSE, TRUE, NOW()),
('Analista Comercial 02', 'analista02@estufasmart.com.br', 'analista02', 'analista123', 'ANALISTA', FALSE, TRUE, NOW()),
('Analista Operações 01', 'operacoes01@estufasmart.com.br', 'op01', 'op123', 'ANALISTA', FALSE, TRUE, NOW()),
('Analista Operações 02', 'operacoes02@estufasmart.com.br', 'op02', 'op123', 'ANALISTA', FALSE, TRUE, NOW()),
('Operador Campo 01', 'campo01@estufasmart.com.br', 'campo01', 'campo123', 'OPERADOR', FALSE, TRUE, NOW()),
('Operador Campo 02', 'campo02@estufasmart.com.br', 'campo02', 'campo123', 'OPERADOR', FALSE, TRUE, NOW()),
('Operador Campo 03', 'campo03@estufasmart.com.br', 'campo03', 'campo123', 'OPERADOR', FALSE, TRUE, NOW()),
('Operador Campo 04', 'campo04@estufasmart.com.br', 'campo04', 'campo123', 'OPERADOR', FALSE, TRUE, NOW()),
('Operador Campo 05', 'campo05@estufasmart.com.br', 'campo05', 'campo123', 'OPERADOR', FALSE, TRUE, NOW()),
('Financeiro 01', 'financeiro01@estufasmart.com.br', 'fin01', 'fin123', 'ANALISTA', FALSE, TRUE, NOW()),
('Financeiro 02', 'financeiro02@estufasmart.com.br', 'fin02', 'fin123', 'ANALISTA', FALSE, TRUE, NOW())
ON DUPLICATE KEY UPDATE
  nome = VALUES(nome),
  senha_hash = VALUES(senha_hash),
  perfil = VALUES(perfil),
  gerente = VALUES(gerente),
  ativo = VALUES(ativo);
