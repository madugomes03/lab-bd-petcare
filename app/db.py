"""Acesso ao banco de dados."""

import os
from contextlib import contextmanager

import mysql.connector
from flask import g


def _obrigatoria(nome):
    valor = os.environ.get(nome)
    if valor is None:
        raise RuntimeError(f"Variável {nome} não definida. Copie .env.example para .env e preencha.")
    return valor


def _parametros_conexao():
    return {
        "host": os.environ.get("DB_HOST", "127.0.0.1"),
        "port": int(os.environ.get("DB_PORT", "3306")),
        "user": _obrigatoria("DB_USER"),
        "password": _obrigatoria("DB_PASSWORD"),
        "database": os.environ.get("DB_NAME", "petcare_db"),
        "charset": "utf8mb4",
        "autocommit": True,  # fora de transação cada comando é confirmado sozinho
    }


def conexao():
    """Uma conexão por requisição HTTP, fechada ao final."""
    if "db" not in g:
        g.db = mysql.connector.connect(**_parametros_conexao())
    return g.db


def fechar_conexao(_erro=None):
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


class Sessao:
    """Executa comandos parametrizados numa conexão (com ou sem transação aberta)."""

    def __init__(self, conn):
        self._conn = conn

    def _cursor(self):
        return self._conn.cursor(prepared=True, dictionary=True)

    def todos(self, sql, params=()):
        cur = self._cursor()
        try:
            cur.execute(sql, params)
            return cur.fetchall()
        finally:
            cur.close()

    def um(self, sql, params=()):
        linhas = self.todos(sql, params)
        return linhas[0] if linhas else None

    def executar(self, sql, params=()):
        """INSERT/UPDATE/DELETE. Devolve o último id gerado (AUTO_INCREMENT)."""
        cur = self._cursor()
        try:
            cur.execute(sql, params)
            return cur.lastrowid
        finally:
            cur.close()


@contextmanager
def transacao():
    """Abre uma transação, que será confirmada ou desfeita ao final do bloco."""
    conn = conexao()
    conn.start_transaction()
    try:
        yield Sessao(conn)
        conn.commit()
    except BaseException:
        conn.rollback()
        raise


# Atalhos para comandos avulsos (autocommit).
def consultar(sql, params=()):
    return Sessao(conexao()).todos(sql, params)


def consultar_um(sql, params=()):
    return Sessao(conexao()).um(sql, params)


def executar(sql, params=()):
    return Sessao(conexao()).executar(sql, params)
