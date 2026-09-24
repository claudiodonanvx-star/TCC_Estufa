-- Popula leituras de teste sem apagar dados existentes.
-- Execute no mesmo banco usado pela API publicada.
-- A tabela sensor_data armazena leituras brutas; as medias sao representadas
-- por valores proximos da faixa media da estufa.

DELIMITER //

DROP PROCEDURE IF EXISTS seed_sensor_data_30_dias //

CREATE PROCEDURE seed_sensor_data_30_dias()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE d DATE;
  DECLARE variacao DOUBLE;
  DECLARE temperatura DOUBLE;
  DECLARE umidade DOUBLE;
  DECLARE solo DOUBLE;
  DECLARE significado VARCHAR(80);

  WHILE i < 30 DO
    SET d = DATE_SUB(CURDATE(), INTERVAL i DAY);
    SET variacao = SIN(i * 0.85);
    SET temperatura = 24.0 + (2.5 * variacao);
    SET umidade = 58.0 - (7.0 * variacao);
    SET solo = 52.0 + (9.0 * COS(i * 0.65));

    IF solo < 30 THEN
      SET significado = 'Solo abaixo do ideal';
    ELSEIF solo > 70 THEN
      SET significado = 'Solo acima do ideal';
    ELSEIF temperatura < 18 THEN
      SET significado = 'Frio';
    ELSEIF temperatura > 30 THEN
      SET significado = 'Quente';
    ELSE
      SET significado = 'Ambiente ideal';
    END IF;

    INSERT INTO sensor_data (
      temperatura,
      umidade,
      umidade_solo,
      significado,
      coletado_em
    ) VALUES (
      ROUND(temperatura, 2),
      ROUND(umidade, 2),
      ROUND(solo, 2),
      significado,
      TIMESTAMP(d, '12:00:00')
    );

    SET i = i + 1;
  END WHILE;

  -- Leituras extras de hoje para validar atualizacao e ordenacao recente.
  INSERT INTO sensor_data (
    temperatura,
    umidade,
    umidade_solo,
    significado,
    coletado_em
  ) VALUES
    (23.70, 35.30, 45.00, 'Solo abaixo do ideal', NOW() - INTERVAL 100 MINUTE),
    (24.10, 36.20, 52.00, 'Ambiente ideal', NOW() - INTERVAL 80 MINUTE),
    (24.40, 37.00, 58.00, 'Ambiente ideal', NOW() - INTERVAL 60 MINUTE),
    (24.00, 36.50, 64.00, 'Ambiente ideal', NOW() - INTERVAL 40 MINUTE),
    (23.80, 35.90, 71.00, 'Solo acima do ideal', NOW() - INTERVAL 20 MINUTE),
    (23.60, 35.50, 55.00, 'Ambiente ideal', NOW());
END //

CALL seed_sensor_data_30_dias() //
DROP PROCEDURE IF EXISTS seed_sensor_data_30_dias //

DELIMITER ;