-- Consolida automaticamente os registros brutos existentes
-- dos dias 03/11/2026 a 17/11/2026.
-- Selecione todo o arquivo, copie e cole no MySQL.
-- Dias sem leituras nao recebem registro.
-- O dia 18/11/2026 nao entra nesta consolidação.

INSERT INTO relatorio_diario (
  data_ref,
  temp_media,
  temp_minima,
  temp_maxima,
  umidade_media,
  umidade_minima,
  umidade_maxima,
  solo_media,
  solo_minima,
  solo_maxima,
  total_leituras,
  atualizado_em
)
SELECT
  DATE(coletado_em),
  ROUND(AVG(temperatura), 2),
  ROUND(MIN(temperatura), 2),
  ROUND(MAX(temperatura), 2),
  ROUND(AVG(umidade), 2),
  ROUND(MIN(umidade), 2),
  ROUND(MAX(umidade), 2),
  ROUND(AVG(COALESCE(umidade_solo, 0)), 2),
  ROUND(MIN(COALESCE(umidade_solo, 0)), 2),
  ROUND(MAX(COALESCE(umidade_solo, 0)), 2),
  COUNT(*),
  NOW()
FROM sensor_data
WHERE coletado_em >= '2026-11-03 00:00:00'
  AND coletado_em < '2026-11-18 00:00:00'
GROUP BY DATE(coletado_em)
ON DUPLICATE KEY UPDATE
  temp_media = VALUES(temp_media),
  temp_minima = VALUES(temp_minima),
  temp_maxima = VALUES(temp_maxima),
  umidade_media = VALUES(umidade_media),
  umidade_minima = VALUES(umidade_minima),
  umidade_maxima = VALUES(umidade_maxima),
  solo_media = VALUES(solo_media),
  solo_minima = VALUES(solo_minima),
  solo_maxima = VALUES(solo_maxima),
  total_leituras = VALUES(total_leituras),
  atualizado_em = NOW();

SELECT
  data_ref,
  temp_media,
  temp_minima,
  temp_maxima,
  umidade_media,
  umidade_minima,
  umidade_maxima,
  solo_media,
  solo_minima,
  solo_maxima,
  total_leituras
FROM relatorio_diario
WHERE data_ref BETWEEN '2026-11-03' AND '2026-11-17'
ORDER BY data_ref;
