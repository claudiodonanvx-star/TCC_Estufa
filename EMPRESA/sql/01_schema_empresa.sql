USE cl202195;

CREATE TABLE IF NOT EXISTS emp_clientes (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  razao_social VARCHAR(150) NOT NULL,
  nome_fantasia VARCHAR(150),
  cnpj VARCHAR(18) NOT NULL UNIQUE,
  segmento VARCHAR(80),
  cidade VARCHAR(80),
  estado VARCHAR(2),
  contato_nome VARCHAR(120),
  contato_email VARCHAR(140),
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emp_leads (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome_contato VARCHAR(120) NOT NULL,
  empresa VARCHAR(140) NOT NULL,
  email VARCHAR(140),
  telefone VARCHAR(40),
  origem VARCHAR(80),
  status VARCHAR(20) NOT NULL,
  valor_estimado DECIMAL(12,2),
  proximo_contato_em DATE,
  observacao VARCHAR(400),
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emp_contratos (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  cliente_id BIGINT NOT NULL,
  plano VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL,
  valor_mensal DECIMAL(12,2) NOT NULL,
  inicio_em DATE NOT NULL,
  fim_em DATE,
  renovacao_automatica BOOLEAN NOT NULL DEFAULT FALSE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_emp_contratos_cliente
    FOREIGN KEY (cliente_id) REFERENCES emp_clientes(id)
);

CREATE TABLE IF NOT EXISTS emp_unidades (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome_unidade VARCHAR(120) NOT NULL,
  cidade VARCHAR(80),
  estado VARCHAR(2),
  quantidade_estufas INT NOT NULL DEFAULT 1,
  ativa BOOLEAN NOT NULL DEFAULT TRUE,
  ultima_sincronizacao DATETIME,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emp_contrato_unidades (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  contrato_id BIGINT NOT NULL,
  unidade_id BIGINT NOT NULL,
  inicio_vinculo DATE NOT NULL,
  fim_vinculo DATE,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_emp_contrato_unidades_contrato
    FOREIGN KEY (contrato_id) REFERENCES emp_contratos(id),
  CONSTRAINT fk_emp_contrato_unidades_unidade
    FOREIGN KEY (unidade_id) REFERENCES emp_unidades(id)
);

CREATE TABLE IF NOT EXISTS emp_atividades (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  unidade_id BIGINT NOT NULL,
  titulo VARCHAR(140) NOT NULL,
  descricao VARCHAR(400),
  prioridade VARCHAR(20) NOT NULL,
  responsavel VARCHAR(120),
  prazo_em DATE,
  concluida BOOLEAN NOT NULL DEFAULT FALSE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_emp_atividades_unidade
    FOREIGN KEY (unidade_id) REFERENCES emp_unidades(id)
);

CREATE TABLE IF NOT EXISTS emp_usuarios (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  email VARCHAR(140) NOT NULL UNIQUE,
  login VARCHAR(60) NOT NULL UNIQUE,
  senha_hash VARCHAR(120) NOT NULL,
  perfil VARCHAR(20) NOT NULL,
  gerente BOOLEAN NOT NULL DEFAULT FALSE,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS emp_sessoes (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT NOT NULL,
  token VARCHAR(80) NOT NULL UNIQUE,
  expira_em DATETIME NOT NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_emp_sessoes_usuario
    FOREIGN KEY (usuario_id) REFERENCES emp_usuarios(id)
);

-- Migração de compatibilidade: modelo antigo tinha emp_unidades.contrato_id.
-- Migra vínculos para emp_contrato_unidades e remove a coluna legada.
SET @has_unidade_contrato_col = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'emp_unidades'
    AND COLUMN_NAME = 'contrato_id'
);

SET @drop_fk_unidade_contrato = (
  SELECT IFNULL(
    CONCAT('ALTER TABLE emp_unidades DROP FOREIGN KEY ', CONSTRAINT_NAME),
    'SELECT 1'
  )
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'emp_unidades'
    AND COLUMN_NAME = 'contrato_id'
    AND REFERENCED_TABLE_NAME IS NOT NULL
  LIMIT 1
);
PREPARE stmt_drop_fk_unidade_contrato FROM @drop_fk_unidade_contrato;
EXECUTE stmt_drop_fk_unidade_contrato;
DEALLOCATE PREPARE stmt_drop_fk_unidade_contrato;

SET @migrate_unidade_contrato = IF(
  @has_unidade_contrato_col > 0,
  'INSERT INTO emp_contrato_unidades (contrato_id, unidade_id, inicio_vinculo, fim_vinculo, ativo, criado_em) '
  'SELECT u.contrato_id, u.id, CURDATE(), NULL, TRUE, NOW() '
  'FROM emp_unidades u '
  'WHERE u.contrato_id IS NOT NULL '
  'AND NOT EXISTS ( '
  '  SELECT 1 FROM emp_contrato_unidades cu '
  '  WHERE cu.contrato_id = u.contrato_id AND cu.unidade_id = u.id '
  ')',
  'SELECT 1'
);
PREPARE stmt_migrate_unidade_contrato FROM @migrate_unidade_contrato;
EXECUTE stmt_migrate_unidade_contrato;
DEALLOCATE PREPARE stmt_migrate_unidade_contrato;

SET @drop_col_unidade_contrato = IF(
  @has_unidade_contrato_col > 0,
  'ALTER TABLE emp_unidades DROP COLUMN contrato_id',
  'SELECT 1'
);
PREPARE stmt_drop_col_unidade_contrato FROM @drop_col_unidade_contrato;
EXECUTE stmt_drop_col_unidade_contrato;
DEALLOCATE PREPARE stmt_drop_col_unidade_contrato;
