-- Popula 30 relatorios diarios anteriores a ontem.
-- Nao insere hoje nem ontem.
-- Use no mesmo banco da API publicada.

DELIMITER //

DROP PROCEDURE IF EXISTS seed_relatorio_diario_30_dias //

CREATE PROCEDURE seed_relatorio_diario_30_dias()
BEGIN
  DECLARE i INT DEFAULT 2;
  DECLARE d DATE;
  DECLARE variacao DOUBLE;
  DECLARE temp_media DOUBLE;
  DECLARE umidade_media DOUBLE;
  DECLARE solo_media DOUBLE;

  WHILE i <= 31 DO
    SET d = DATE_SUB(CURDATE(), INTERVAL i DAY);
    SET variacao = SIN(i * 0.65);
    SET temp_media = 24.0 + (2.8 * variacao);
    SET umidade_media = 58.0 - (9.0 * variacao);
    SET solo_media = 52.0 + (14.0 * COS(i * 0.48));

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
    ) VALUES (
      d,
      ROUND(temp_media, 2),
      ROUND(temp_media - 2.5, 2),
      ROUND(temp_media + 2.5, 2),
      ROUND(umidade_media, 2),
      ROUND(GREATEST(0, umidade_media - 10), 2),
      ROUND(LEAST(100, umidade_media + 10), 2),
      ROUND(solo_media, 2),
      ROUND(GREATEST(0, solo_media - 12), 2),
      ROUND(LEAST(100, solo_media + 12), 2),
      72 + MOD(i * 7, 49),
      NOW()
    ) ON DUPLICATE KEY UPDATE
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

    SET i = i + 1;
  END WHILE;
END //

CALL seed_relatorio_diario_30_dias() //
DROP PROCEDURE IF EXISTS seed_relatorio_diario_30_dias //

DELIMITER ;

-- Conferencia: deve retornar 30 dias, de CURDATE()-31 ate CURDATE()-2.
SELECT
  data_ref,
  temp_media,
  umidade_media,
  solo_media,
  total_leituras
FROM relatorio_diario
WHERE data_ref BETWEEN DATE_SUB(CURDATE(), INTERVAL 31 DAY)
                   AND DATE_SUB(CURDATE(), INTERVAL 2 DAY)
ORDER BY data_ref;
