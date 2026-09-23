-- Migration 10: nome de usuario para o novo cadastro simplificado.
-- Execute uma vez no mesmo banco usado pela API.
USE dona2006;

SET @cliente_usuario_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'clienteestufa'
    AND COLUMN_NAME = 'usuario'
);
SET @sql_cliente_usuario = IF(
  @cliente_usuario_exists = 0,
  'ALTER TABLE clienteestufa ADD COLUMN usuario VARCHAR(100) NULL',
  'SELECT 1'
);
PREPARE stmt_cliente_usuario FROM @sql_cliente_usuario;
EXECUTE stmt_cliente_usuario;
DEALLOCATE PREPARE stmt_cliente_usuario;

SET @pendente_usuario_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'clienteestufa_pendente'
    AND COLUMN_NAME = 'usuario'
);
SET @sql_pendente_usuario = IF(
  @pendente_usuario_exists = 0,
  'ALTER TABLE clienteestufa_pendente ADD COLUMN usuario VARCHAR(100) NULL',
  'SELECT 1'
);
PREPARE stmt_pendente_usuario FROM @sql_pendente_usuario;
EXECUTE stmt_pendente_usuario;
DEALLOCATE PREPARE stmt_pendente_usuario;

SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('clienteestufa', 'clienteestufa_pendente')
  AND COLUMN_NAME = 'usuario';