-- Arquivo de seed compatível com MySQL 5.7 para popular dados no banco da API de sensores e relatórios.
-- Ajuste o USE para o schema/database correto antes de executar.
-- Exemplo: USE dona2006;

-- 1) Relatórios diários consolidados de 2023 até 2026-05-18
SET SQL_SAFE_UPDATES = 0;
DELETE FROM relatorio_diario WHERE data_ref BETWEEN '2023-01-01' AND '2026-05-18';

DELIMITER //
DROP PROCEDURE IF EXISTS seed_relatorio_diario //
CREATE PROCEDURE seed_relatorio_diario()
BEGIN
  DECLARE d DATE DEFAULT '2023-01-01';
  DECLARE dia_ano INT;
  DECLARE temp_media DOUBLE;
  DECLARE temp_minima DOUBLE;
  DECLARE temp_maxima DOUBLE;
  DECLARE umidade_media DOUBLE;
  DECLARE umidade_minima DOUBLE;
  DECLARE umidade_maxima DOUBLE;
  DECLARE solo_media DOUBLE;
  DECLARE solo_minima DOUBLE;
  DECLARE solo_maxima DOUBLE;
  DECLARE total_leituras INT;

  WHILE d <= '2026-05-18' DO
    SET dia_ano = DAYOFYEAR(d);
    SET temp_media = 22 + 5 * ((1 + COS(2 * PI() * dia_ano / 365 - 0.3)) / 2);
    SET temp_minima = temp_media - 5.0 - 0.5 * COS(2 * PI() * dia_ano / 365);
    SET temp_maxima = temp_media + 4.5 + 0.5 * SIN(2 * PI() * dia_ano / 365);
    SET umidade_media = 65 + 12 * SIN(2 * PI() * dia_ano / 365 + 0.8);
    SET umidade_minima = umidade_media - 12.0 + 2.0 * COS(2 * PI() * dia_ano / 365 + 1.1);
    SET umidade_maxima = umidade_media + 10.0 + 2.0 * SIN(2 * PI() * dia_ano / 365 + 0.7);
    SET solo_media = 42 + 15 * COS(2 * PI() * dia_ano / 365 + 0.2);
    SET solo_minima = solo_media - 10.0 + 1.5 * SIN(2 * PI() * dia_ano / 365);
    SET solo_maxima = solo_media + 10.0 + 1.5 * COS(2 * PI() * dia_ano / 365);
    SET total_leituras = 90 + FLOOR(30 * ABS(SIN(dia_ano / 14.0)));

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
      total_leituras
    ) VALUES (
      d,
      ROUND(temp_media, 2),
      ROUND(temp_minima, 2),
      ROUND(temp_maxima, 2),
      ROUND(umidade_media, 2),
      ROUND(umidade_minima, 2),
      ROUND(umidade_maxima, 2),
      ROUND(solo_media, 2),
      ROUND(solo_minima, 2),
      ROUND(solo_maxima, 2),
      total_leituras
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
      total_leituras = VALUES(total_leituras);

    SET d = DATE_ADD(d, INTERVAL 1 DAY);
  END WHILE;
END //
CALL seed_relatorio_diario() //
DROP PROCEDURE IF EXISTS seed_relatorio_diario //

-- 2) Leituras brutas de sensor para os últimos 90 dias
DELETE FROM sensor_data WHERE coletado_em BETWEEN '2026-02-18 00:00:00' AND '2026-05-18 23:59:59';

DROP PROCEDURE IF EXISTS seed_sensor_data //
CREATE PROCEDURE seed_sensor_data()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE d DATE DEFAULT '2026-02-18';
  DECLARE temp DOUBLE;
  DECLARE umidade DOUBLE;
  DECLARE solo DOUBLE;
  DECLARE significado VARCHAR(20);
  DECLARE ts DATETIME;

  WHILE i < 90 DO
    SET temp = 24 + 4.5 * SIN(2 * PI() * (i / 30.0) + 0.4);
    SET umidade = 68 + 14 * COS(2 * PI() * (i / 20.0) + 0.9);
    SET solo = 45 + 11 * SIN(2 * PI() * (i / 18.0) - 0.6);

    IF temp > 29 OR umidade > 85 OR solo < 25 THEN
      SET significado = 'Crítico';
    ELSEIF temp > 27 OR umidade > 80 OR solo < 30 THEN
      SET significado = 'Atenção';
    ELSE
      SET significado = 'Normal';
    END IF;

    SET ts = TIMESTAMP(d, MAKETIME(6 + MOD(i, 12), 15, 0));

    INSERT INTO sensor_data (
      temperatura,
      umidade,
      umidade_solo,
      significado,
      coletado_em
    ) VALUES (
      ROUND(temp, 2),
      ROUND(umidade, 2),
      ROUND(solo, 2),
      significado,
      ts
    );

    SET i = i + 1;
    SET d = DATE_ADD(d, INTERVAL 1 DAY);
  END WHILE;
END //
CALL seed_sensor_data() //
DROP PROCEDURE IF EXISTS seed_sensor_data //

DELIMITER ;
SET SQL_SAFE_UPDATES = 1;
