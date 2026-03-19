-- Migration: Add soil moisture min/max to cultivos table
-- Version: 08
-- Date: 2026-03-19

USE dona2006;

-- Check if columns exist before adding them (prevents duplicate column errors)
SET @has_umidade_solo_minima = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'cultivos'
    AND COLUMN_NAME = 'umidade_solo_minima'
);

SET @has_umidade_solo_maxima = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'cultivos'
    AND COLUMN_NAME = 'umidade_solo_maxima'
);

-- Add umidade_solo_minima column if it doesn't exist
SET @add_col_minima = IF(
  @has_umidade_solo_minima = 0,
  'ALTER TABLE cultivos ADD COLUMN umidade_solo_minima FLOAT NOT NULL DEFAULT 30.0',
  'SELECT 1'
);
PREPARE stmt_add_col_minima FROM @add_col_minima;
EXECUTE stmt_add_col_minima;
DEALLOCATE PREPARE stmt_add_col_minima;

-- Add umidade_solo_maxima column if it doesn't exist
SET @add_col_maxima = IF(
  @has_umidade_solo_maxima = 0,
  'ALTER TABLE cultivos ADD COLUMN umidade_solo_maxima FLOAT NOT NULL DEFAULT 70.0',
  'SELECT 1'
);
PREPARE stmt_add_col_maxima FROM @add_col_maxima;
EXECUTE stmt_add_col_maxima;
DEALLOCATE PREPARE stmt_add_col_maxima;

-- Verify the columns were added
SELECT 
  COLUMN_NAME,
  COLUMN_TYPE,
  IS_NULLABLE,
  COLUMN_DEFAULT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'cultivos'
  AND COLUMN_NAME IN ('umidade_solo_minima', 'umidade_solo_maxima')
ORDER BY ORDINAL_POSITION;
