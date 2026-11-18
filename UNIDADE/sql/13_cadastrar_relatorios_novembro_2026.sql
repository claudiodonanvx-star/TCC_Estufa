-- Histórico diário de 03/11/2026 a 17/11/2026.
-- Selecione tudo daqui ate o final, copie e cole no MySQL.
-- Substitua os valores destacados abaixo antes de executar.
-- O dia 18/11/2026 nao esta incluido: hoje sera contabilizado pelo sistema.

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
) VALUES
  ('2026-11-03', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-04', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-05', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-06', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-07', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-08', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-09', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-10', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-11', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-12', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-13', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-14', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-15', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-16', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW()),
  ('2026-11-17', 24.00, 24.00, 24.00, 65.00, 65.00, 65.00, 50.00, 50.00, 50.00, 0, NOW())
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
