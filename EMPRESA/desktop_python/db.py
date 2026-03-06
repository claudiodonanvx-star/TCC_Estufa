from __future__ import annotations

import os
import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Any

import mysql.connector
from dotenv import load_dotenv


load_dotenv()


TABLE_NAME_PATTERN = re.compile(r"^[A-Za-z0-9_]+$")

# Minimal bytes for a simulated PDF payload stored in MySQL.
SIMULATED_PDF_BYTES = (
    b"%PDF-1.4\n"
    b"% Simulacao de boleto\n"
    b"1 0 obj << /Type /Catalog >> endobj\n"
    b"trailer << /Root 1 0 R >>\n"
    b"%%EOF\n"
)


@dataclass(frozen=True)
class DbConfig:
    host: str
    port: int
    user: str
    password: str
    database: str

    @staticmethod
    def from_env() -> "DbConfig":
        return DbConfig(
            host=os.getenv("DB_HOST", "143.106.241.3"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER", ""),
            password=os.getenv("DB_PASSWORD", ""),
            database=os.getenv("DB_NAME", ""),
        )


class DatabaseClient:
    def __init__(self, config: DbConfig) -> None:
        self.config = config

    def _connect(self):
        return mysql.connector.connect(
            host=self.config.host,
            port=self.config.port,
            user=self.config.user,
            password=self.config.password,
            database=self.config.database,
            autocommit=True,
        )

    def _fetch_all(self, query: str, params: tuple | None = None) -> list[dict[str, Any]]:
        with self._connect() as connection:
            with connection.cursor(dictionary=True) as cursor:
                cursor.execute(query, params or ())
                return cursor.fetchall()

    def _execute(self, query: str, params: tuple | None = None) -> None:
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, params or ())

    def _fetch_one(self, query: str, params: tuple | None = None) -> dict[str, Any]:
        with self._connect() as connection:
            with connection.cursor(dictionary=True) as cursor:
                cursor.execute(query, params or ())
                row = cursor.fetchone()
                return row or {}

    def ping(self) -> bool:
        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        return True

    def list_emp_tables(self) -> list[str]:
        query = """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = %s
              AND table_name LIKE 'emp\\_%'
            ORDER BY table_name
        """

        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, (self.config.database,))
                return [row[0] for row in cursor.fetchall()]

    def count_rows(self, table_name: str) -> int:
        safe_table_name = self._validate_table_name(table_name)
        query = f"SELECT COUNT(*) FROM `{safe_table_name}`"

        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query)
                value = cursor.fetchone()
                return int(value[0]) if value else 0

    def table_columns(self, table_name: str) -> list[str]:
        safe_table_name = self._validate_table_name(table_name)
        query = """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = %s
              AND table_name = %s
            ORDER BY ordinal_position
        """

        with self._connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, (self.config.database, safe_table_name))
                return [row[0] for row in cursor.fetchall()]

    def fetch_rows(self, table_name: str, limit: int = 100) -> list[dict[str, Any]]:
        safe_table_name = self._validate_table_name(table_name)
        limit = max(1, min(limit, 500))
        columns = self.table_columns(safe_table_name)
        order_clause = "ORDER BY id DESC" if "id" in columns else ""
        query = f"SELECT * FROM `{safe_table_name}` {order_clause} LIMIT %s"

        with self._connect() as connection:
            with connection.cursor(dictionary=True) as cursor:
                cursor.execute(query, (limit,))
                return cursor.fetchall()

    def _validate_table_name(self, table_name: str) -> str:
        if not TABLE_NAME_PATTERN.match(table_name):
            raise ValueError("Nome de tabela inválido.")
        if not table_name.startswith("emp_"):
            raise ValueError("Apenas tabelas com prefixo emp_ são permitidas.")
        return table_name

    def _column_exists(self, table_name: str, column_name: str) -> bool:
        query = """
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = %s
              AND table_name = %s
              AND column_name = %s
            LIMIT 1
        """
        row = self._fetch_one(query, (self.config.database, table_name, column_name))
        return bool(row)

    def ensure_finance_schema(self) -> None:
        create_boletos = """
            CREATE TABLE IF NOT EXISTS emp_boletos (
                id BIGINT(20) NOT NULL AUTO_INCREMENT,
                unidade_id BIGINT(20) NOT NULL,
                competencia DATE NOT NULL,
                vencimento DATE NOT NULL,
                valor DECIMAL(12,2) NOT NULL DEFAULT 0.00,
                pago_em DATE DEFAULT NULL,
                status_boleto ENUM('PENDENTE', 'PAGO') NOT NULL DEFAULT 'PENDENTE',
                arquivo_pdf LONGBLOB DEFAULT NULL,
                nome_arquivo VARCHAR(160) DEFAULT NULL,
                criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (id),
                UNIQUE KEY uk_emp_boletos_unidade_competencia (unidade_id, competencia),
                KEY idx_emp_boletos_vencimento (vencimento),
                CONSTRAINT fk_emp_boletos_unidade FOREIGN KEY (unidade_id) REFERENCES emp_unidades (id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        """
        self._execute(create_boletos)

        if not self._column_exists("emp_unidades", "status_financeiro"):
            self._execute(
                """
                    ALTER TABLE emp_unidades
                    ADD COLUMN status_financeiro ENUM('ATIVO', 'CANCELADO', 'BFP')
                    NOT NULL DEFAULT 'ATIVO'
                    AFTER ativa
                """
            )

    def bootstrap_finance_data(self, reset_existing: bool = False) -> None:
        self.ensure_finance_schema()
        if reset_existing:
            self._execute("DELETE FROM emp_boletos")
        self._seed_boletos_for_units()
        self.sync_unit_financial_status()

    def _seed_boletos_for_units(self) -> None:
        units = self._fetch_all(
            """
                SELECT
                    u.id,
                    u.criado_em,
                    u.quantidade_estufas,
                    MIN(c.inicio_em) AS inicio_contrato
                FROM emp_unidades u
                LEFT JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id
                LEFT JOIN emp_contratos c ON c.id = cu.contrato_id
                GROUP BY u.id, u.criado_em, u.quantidade_estufas
                ORDER BY id ASC
            """
        )

        today = date.today()
        current_month = date(today.year, today.month, 1)

        insert_sql = """
            INSERT INTO emp_boletos (
                unidade_id,
                competencia,
                vencimento,
                valor,
                pago_em,
                status_boleto,
                arquivo_pdf,
                nome_arquivo
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE id = id
        """

        with self._connect() as connection:
            with connection.cursor() as cursor:
                for unit in units:
                    unit_id = int(unit["id"])
                    created = unit.get("criado_em") or datetime.now()
                    contract_start = unit.get("inicio_contrato")
                    estufas = int(unit.get("quantidade_estufas") or 1)

                    if isinstance(contract_start, date):
                        start_month = date(contract_start.year, contract_start.month, 1)
                    elif isinstance(created, datetime):
                        start_month = date(created.year, created.month, 1)
                    else:
                        start_month = date.today()

                    for competencia in self._iter_months(start_month, current_month):
                        vencimento = self._month_due_date(competencia)
                        pago_em = self._simulate_payment_date(unit_id, competencia, vencimento)
                        status_boleto = "PAGO" if pago_em else "PENDENTE"
                        valor = self._simulate_amount(estufas)
                        file_name = f"boleto_unidade_{unit_id}_{competencia.strftime('%Y_%m')}.pdf"

                        cursor.execute(
                            insert_sql,
                            (
                                unit_id,
                                competencia,
                                vencimento,
                                valor,
                                pago_em,
                                status_boleto,
                                SIMULATED_PDF_BYTES,
                                file_name,
                            ),
                        )

    def _simulate_amount(self, estufas: int) -> float:
        base = 350.0
        per_estufa = 120.0
        return round(base + (estufas * per_estufa), 2)

    def _simulate_payment_date(self, unit_id: int, competencia: date, vencimento: date) -> date | None:
        current_month = date.today().replace(day=1)
        if competencia >= current_month:
            return None

        key = (unit_id * 37 + competencia.month + competencia.year) % 7

        if key in (0, 1):
            return vencimento - timedelta(days=1)
        if key == 2:
            return vencimento + timedelta(days=3)
        if key == 3:
            return None
        if key == 4:
            return vencimento + timedelta(days=8)
        return vencimento + timedelta(days=1)

    def _month_due_date(self, month_start: date) -> date:
        # Day 10 is the fixed boleto due day for simulation.
        return date(month_start.year, month_start.month, 10)

    def _iter_months(self, start_month: date, end_month: date):
        cursor = date(start_month.year, start_month.month, 1)
        while cursor <= end_month:
            yield cursor
            if cursor.month == 12:
                cursor = date(cursor.year + 1, 1, 1)
            else:
                cursor = date(cursor.year, cursor.month + 1, 1)

    def sync_unit_financial_status(self) -> None:
        query = """
            UPDATE emp_unidades u
            LEFT JOIN (
                SELECT
                    unidade_id,
                    MAX(
                        CASE
                            WHEN pago_em IS NULL
                             AND DATE_ADD(vencimento, INTERVAL 5 DAY) < CURDATE()
                            THEN 1
                            ELSE 0
                        END
                    ) AS has_bfp
                FROM emp_boletos
                GROUP BY unidade_id
            ) b ON b.unidade_id = u.id
            SET u.status_financeiro = CASE
                WHEN IFNULL(u.ativa, 0) = 0 THEN 'CANCELADO'
                WHEN IFNULL(b.has_bfp, 0) = 1 THEN 'BFP'
                ELSE 'ATIVO'
            END
        """
        self._execute(query)

    def get_finance_status_summary(self) -> list[dict[str, Any]]:
        query = """
            SELECT status_financeiro AS status, COUNT(*) AS total
            FROM emp_unidades
            GROUP BY status_financeiro
            ORDER BY FIELD(status_financeiro, 'ATIVO', 'BFP', 'CANCELADO')
        """
        return self._fetch_all(query)

    def list_finance_units(self) -> list[dict[str, Any]]:
        query = """
            SELECT
                u.id,
                u.nome_unidade,
                u.cidade,
                u.estado,
                u.status_financeiro,
                u.criado_em,
                COUNT(b.id) AS total_boletos,
                SUM(CASE WHEN b.pago_em IS NULL THEN 1 ELSE 0 END) AS boletos_pendentes,
                SUM(
                    CASE
                        WHEN b.pago_em IS NULL
                         AND DATE_ADD(b.vencimento, INTERVAL 5 DAY) < CURDATE()
                        THEN 1
                        ELSE 0
                    END
                ) AS boletos_bfp
            FROM emp_unidades u
            LEFT JOIN emp_boletos b ON b.unidade_id = u.id
            GROUP BY u.id, u.nome_unidade, u.cidade, u.estado, u.status_financeiro, u.criado_em
            ORDER BY FIELD(u.status_financeiro, 'BFP', 'ATIVO', 'CANCELADO'), u.nome_unidade ASC
        """
        return self._fetch_all(query)

    def get_unit_boletos(self, unit_id: int, limit: int = 240) -> list[dict[str, Any]]:
        capped_limit = max(1, min(limit, 500))
        query = """
            SELECT
                id AS boleto_id,
                competencia,
                vencimento,
                valor,
                pago_em,
                status_boleto,
                CASE
                    WHEN pago_em IS NULL
                     AND DATE_ADD(vencimento, INTERVAL 5 DAY) < CURDATE()
                    THEN 'BFP'
                    WHEN pago_em IS NULL
                    THEN 'PENDENTE'
                    WHEN pago_em <= DATE_ADD(vencimento, INTERVAL 5 DAY)
                    THEN 'PAGO'
                    ELSE 'PAGO_APOS_5_DIAS'
                END AS regra_5_dias,
                CASE WHEN arquivo_pdf IS NULL THEN 'NAO' ELSE 'SIM' END AS possui_pdf,
                nome_arquivo
            FROM emp_boletos
            WHERE unidade_id = %s
            ORDER BY competencia DESC
            LIMIT %s
        """
        return self._fetch_all(query, (unit_id, capped_limit))

    def get_boleto_pdf(self, boleto_id: int) -> tuple[str, bytes] | None:
        query = """
            SELECT nome_arquivo, arquivo_pdf
            FROM emp_boletos
            WHERE id = %s
            LIMIT 1
        """
        row = self._fetch_one(query, (boleto_id,))
        if not row:
            return None

        file_name = str(row.get("nome_arquivo") or f"boleto_{boleto_id}.pdf")
        payload = row.get("arquivo_pdf")
        if payload is None:
            return None

        if isinstance(payload, memoryview):
            payload = payload.tobytes()
        elif isinstance(payload, bytearray):
            payload = bytes(payload)

        if not isinstance(payload, bytes):
            return None
        return file_name, payload

    def mark_boleto_paid(self, boleto_id: int, payment_date: date | None = None) -> None:
        paid_date = payment_date or date.today()
        query = """
            UPDATE emp_boletos
            SET
                pago_em = COALESCE(pago_em, %s),
                status_boleto = 'PAGO'
            WHERE id = %s
        """
        self._execute(query, (paid_date, boleto_id))
        self.sync_unit_financial_status()

    def get_leads_funnel(self) -> list[dict[str, Any]]:
        query = """
            SELECT COALESCE(status, 'SEM_STATUS') AS status, COUNT(*) AS total
            FROM emp_leads
            GROUP BY COALESCE(status, 'SEM_STATUS')
            ORDER BY total DESC, status ASC
        """
        return self._fetch_all(query)

    def get_contract_alerts(self, days: int = 30) -> list[dict[str, Any]]:
        query = """
            SELECT
                c.id AS contrato_id,
                cl.nome_fantasia AS cliente,
                c.status,
                c.fim_em,
                DATEDIFF(c.fim_em, CURDATE()) AS dias_para_fim,
                c.valor_mensal
            FROM emp_contratos c
            JOIN emp_clientes cl ON cl.id = c.cliente_id
            WHERE c.fim_em IS NOT NULL
              AND c.status IN ('ATIVO', 'TESTE')
              AND DATEDIFF(c.fim_em, CURDATE()) <= %s
            ORDER BY dias_para_fim ASC, c.fim_em ASC
        """
        return self._fetch_all(query, (days,))

    def get_activity_alerts(self, days: int = 7) -> list[dict[str, Any]]:
        query = """
            SELECT
                a.id AS atividade_id,
                a.titulo,
                COALESCE(u.nome_unidade, 'Sem unidade') AS unidade,
                a.prioridade,
                a.prazo_em,
                DATEDIFF(a.prazo_em, CURDATE()) AS dias_para_prazo
            FROM emp_atividades a
            LEFT JOIN emp_unidades u ON u.id = a.unidade_id
            WHERE IFNULL(a.concluida, 0) = 0
              AND a.prazo_em IS NOT NULL
              AND DATEDIFF(a.prazo_em, CURDATE()) <= %s
            ORDER BY dias_para_prazo ASC,
                     FIELD(a.prioridade, 'CRITICA', 'ALTA', 'MEDIA', 'BAIXA')
        """
        return self._fetch_all(query, (days,))

    def list_clients(self) -> list[dict[str, Any]]:
        query = """
            SELECT id, nome_fantasia, cidade, estado, segmento, ativo
            FROM emp_clientes
            ORDER BY nome_fantasia ASC
        """
        return self._fetch_all(query)

    def get_client_overview(self, client_id: int) -> dict[str, Any]:
        query = """
            SELECT
                cl.nome_fantasia AS cliente,
                (
                    SELECT COUNT(*)
                    FROM emp_contratos c
                    WHERE c.cliente_id = cl.id
                ) AS contratos,
                (
                    SELECT COUNT(DISTINCT u.id)
                    FROM emp_unidades u
                    JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id
                    JOIN emp_contratos c ON c.id = cu.contrato_id
                    WHERE c.cliente_id = cl.id
                ) AS unidades,
                (
                    SELECT COALESCE(SUM(c.valor_mensal), 0)
                    FROM emp_contratos c
                    WHERE c.cliente_id = cl.id
                      AND c.status = 'ATIVO'
                ) AS receita_ativa,
                (
                    SELECT COUNT(DISTINCT a.id)
                    FROM emp_atividades a
                    JOIN emp_unidades u ON u.id = a.unidade_id
                    JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id
                    JOIN emp_contratos c ON c.id = cu.contrato_id
                    WHERE c.cliente_id = cl.id
                      AND IFNULL(a.concluida, 0) = 0
                ) AS atividades_pendentes
            FROM emp_clientes cl
            WHERE cl.id = %s
        """
        return self._fetch_one(query, (client_id,))

    def get_client_contracts(self, client_id: int) -> list[dict[str, Any]]:
        query = """
            SELECT
                id,
                plano,
                status,
                inicio_em,
                fim_em,
                valor_mensal,
                renovacao_automatica
            FROM emp_contratos
            WHERE cliente_id = %s
            ORDER BY fim_em ASC
        """
        return self._fetch_all(query, (client_id,))

    def get_client_units(self, client_id: int) -> list[dict[str, Any]]:
        query = """
            SELECT DISTINCT
                u.id,
                u.nome_unidade,
                u.cidade,
                u.estado,
                u.quantidade_estufas,
                u.ativa
            FROM emp_unidades u
            JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id
            JOIN emp_contratos c ON c.id = cu.contrato_id
            WHERE c.cliente_id = %s
            ORDER BY u.nome_unidade ASC
        """
        return self._fetch_all(query, (client_id,))

    def get_client_activities(self, client_id: int, limit: int = 100) -> list[dict[str, Any]]:
        capped_limit = max(1, min(limit, 500))
        query = """
            SELECT DISTINCT
                a.id,
                a.titulo,
                a.prioridade,
                a.prazo_em,
                a.concluida,
                COALESCE(u.nome_unidade, 'Sem unidade') AS unidade
            FROM emp_atividades a
            LEFT JOIN emp_unidades u ON u.id = a.unidade_id
            LEFT JOIN emp_contrato_unidades cu ON cu.unidade_id = u.id
            LEFT JOIN emp_contratos c ON c.id = cu.contrato_id
            WHERE c.cliente_id = %s
            ORDER BY IFNULL(a.concluida, 0) ASC, a.prazo_em ASC
            LIMIT %s
        """
        return self._fetch_all(query, (client_id, capped_limit))

    def get_client_paid_boletos(self, client_id: int, limit: int = 2000) -> list[dict[str, Any]]:
        capped_limit = max(1, min(limit, 5000))
        query = """
            SELECT
                b.id AS boleto_id,
                u.nome_unidade,
                b.competencia,
                b.vencimento,
                b.pago_em,
                b.valor,
                CASE
                    WHEN b.pago_em <= DATE_ADD(b.vencimento, INTERVAL 5 DAY)
                    THEN 'PAGO_REGULAR'
                    ELSE 'PAGO_APOS_5_DIAS'
                END AS comportamento_pagamento,
                DATEDIFF(b.pago_em, b.vencimento) AS atraso_dias,
                b.nome_arquivo
            FROM emp_boletos b
            JOIN emp_unidades u ON u.id = b.unidade_id
            WHERE b.status_boleto = 'PAGO'
              AND b.pago_em IS NOT NULL
              AND EXISTS (
                  SELECT 1
                  FROM emp_contrato_unidades cu
                  JOIN emp_contratos c ON c.id = cu.contrato_id
                  WHERE cu.unidade_id = u.id
                    AND c.cliente_id = %s
              )
            ORDER BY b.pago_em DESC, b.competencia DESC
            LIMIT %s
        """
        return self._fetch_all(query, (client_id, capped_limit))

    def get_client_paid_boletos_summary(self, client_id: int) -> dict[str, Any]:
        query = """
            SELECT
                COALESCE(cl.nome_fantasia, 'Cliente') AS cliente,
                COALESCE(COUNT(pb.boleto_id), 0) AS total_pagos,
                COALESCE(SUM(CASE WHEN pb.pago_em <= DATE_ADD(pb.vencimento, INTERVAL 5 DAY) THEN 1 ELSE 0 END), 0) AS pagos_regulares,
                COALESCE(SUM(CASE WHEN pb.pago_em > DATE_ADD(pb.vencimento, INTERVAL 5 DAY) THEN 1 ELSE 0 END), 0) AS pagos_apos_5_dias,
                MIN(pb.competencia) AS primeira_competencia_paga,
                MAX(pb.pago_em) AS ultimo_pagamento,
                ROUND(AVG(DATEDIFF(pb.pago_em, pb.vencimento)), 2) AS media_atraso_dias
            FROM emp_clientes cl
            LEFT JOIN (
                SELECT DISTINCT
                    b.id AS boleto_id,
                    b.unidade_id,
                    b.competencia,
                    b.vencimento,
                    b.pago_em
                FROM emp_boletos b
                WHERE b.status_boleto = 'PAGO'
                  AND b.pago_em IS NOT NULL
            ) pb ON EXISTS (
                SELECT 1
                FROM emp_contrato_unidades cu
                JOIN emp_contratos c ON c.id = cu.contrato_id
                WHERE cu.unidade_id = pb.unidade_id
                  AND c.cliente_id = cl.id
            )
            WHERE cl.id = %s
            GROUP BY cl.nome_fantasia
        """
        return self._fetch_one(query, (client_id,))

    def get_client_adimplencia(self, client_id: int) -> dict[str, Any]:
        query = """
            SELECT
                COUNT(*) AS boletos_avaliados,
                SUM(
                    CASE
                        WHEN b.pago_em IS NOT NULL
                         AND b.pago_em <= DATE_ADD(b.vencimento, INTERVAL 5 DAY)
                        THEN 1
                        ELSE 0
                    END
                ) AS pagos_no_prazo,
                SUM(
                    CASE
                        WHEN b.pago_em IS NOT NULL
                         AND b.pago_em > DATE_ADD(b.vencimento, INTERVAL 5 DAY)
                        THEN 1
                        ELSE 0
                    END
                ) AS pagos_apos_5_dias,
                SUM(
                    CASE
                        WHEN b.pago_em IS NULL
                         AND DATE_ADD(b.vencimento, INTERVAL 5 DAY) < CURDATE()
                        THEN 1
                        ELSE 0
                    END
                ) AS vencidos_em_aberto,
                ROUND(
                    CASE
                        WHEN COUNT(*) = 0 THEN 0
                        ELSE (
                            SUM(
                                CASE
                                    WHEN b.pago_em IS NOT NULL
                                     AND b.pago_em <= DATE_ADD(b.vencimento, INTERVAL 5 DAY)
                                    THEN 1
                                    ELSE 0
                                END
                            ) * 100.0
                        ) / COUNT(*)
                    END,
                    2
                ) AS adimplencia_percentual
            FROM emp_boletos b
            WHERE b.vencimento <= CURDATE()
              AND EXISTS (
                  SELECT 1
                  FROM emp_contrato_unidades cu
                  JOIN emp_contratos c ON c.id = cu.contrato_id
                  WHERE cu.unidade_id = b.unidade_id
                    AND c.cliente_id = %s
              )
        """

        row = self._fetch_one(query, (client_id,))
        if not row:
            return {
                "boletos_avaliados": 0,
                "pagos_no_prazo": 0,
                "pagos_apos_5_dias": 0,
                "vencidos_em_aberto": 0,
                "adimplencia_percentual": 0.0,
            }

        return {
            "boletos_avaliados": int(row.get("boletos_avaliados") or 0),
            "pagos_no_prazo": int(row.get("pagos_no_prazo") or 0),
            "pagos_apos_5_dias": int(row.get("pagos_apos_5_dias") or 0),
            "vencidos_em_aberto": int(row.get("vencidos_em_aberto") or 0),
            "adimplencia_percentual": float(row.get("adimplencia_percentual") or 0.0),
        }
