"""Consultas SQL da aplicação (item B2).

Cada SQL abaixo é uma string constante. Valores digitados pelo usuário entram
somente pelos parâmetros (%s) — nunca por concatenação.
"""
import db


# ------------------------------------------------------------ listas para <select>
def opcoes_ongs():
    return [(r["id_ong"], r["nome"]) for r in db.consultar("SELECT id_ong, nome FROM Ong ORDER BY nome")]


def opcoes_parceiros():
    return [(r["id_parceiro"], r["nome"]) for r in db.consultar("SELECT id_parceiro, nome FROM Parceiro ORDER BY nome")]


def opcoes_adm_sistema():
    return [
        (r["id_pessoa"], r["nome"])
        for r in db.consultar(
            "SELECT p.id_pessoa, p.nome FROM AdmSistema a JOIN Pessoa p ON p.id_pessoa = a.id_pessoa ORDER BY p.nome"
        )
    ]


def opcoes_veterinarios():
    return [
        (r["id_pessoa"], r["nome"])
        for r in db.consultar(
            "SELECT p.id_pessoa, p.nome FROM Veterinario v JOIN Pessoa p ON p.id_pessoa = v.id_pessoa ORDER BY p.nome"
        )
    ]


def listar_especies():
    return [r["especie"] for r in db.consultar("SELECT DISTINCT especie FROM Animal ORDER BY especie")]


# ------------------------------------------------------------------ CRUD: Animal
def listar_animais():
    return db.consultar(
        """SELECT a.id_animal, a.nome, a.especie, a.raca, a.sexo, a.data_nascimento,
                  a.status_atual, o.nome AS ong
             FROM Animal a
             JOIN Ong o ON o.id_ong = a.id_ong
            ORDER BY a.nome"""
    )


def obter_animal(id_animal):
    return db.consultar_um(
        """SELECT id_animal, id_ong, nome, especie, raca, sexo, data_nascimento, descricao, status_atual
             FROM Animal WHERE id_animal = %s""",
        (id_animal,),
    )


def excluir_animal(id_animal):
    # Prontuario e SituacaoAnimal saem em cascata; pedidos e consultas bloqueiam (RESTRICT).
    db.executar("DELETE FROM Animal WHERE id_animal = %s", (id_animal,))


def historico_animal(id_animal):
    return db.consultar(
        """SELECT registro, data_registro, motivo, status, data_inicio, data_fim
             FROM SituacaoAnimal WHERE id_animal = %s ORDER BY registro""",
        (id_animal,),
    )


# --------------------------------------------------------------------- CRUD: ONG
def listar_ongs():
    return db.consultar(
        "SELECT id_ong, nome, cnpj, email, telefone, situacao_cadastro, data_cadastro FROM Ong ORDER BY nome"
    )


def obter_ong(id_ong):
    return db.consultar_um(
        """SELECT id_ong, id_adm_sistema, nome, cnpj, razao_social, email, endereco, telefone, situacao_cadastro
             FROM Ong WHERE id_ong = %s""",
        (id_ong,),
    )


def inserir_ong(d):
    return db.executar(
        """INSERT INTO Ong (id_adm_sistema, nome, cnpj, razao_social, email, endereco, telefone,
                            data_cadastro, situacao_cadastro)
           VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), %s)""",
        (d["id_adm_sistema"], d["nome"], d["cnpj"], d["razao_social"], d["email"], d["endereco"],
         d["telefone"], d["situacao_cadastro"]),
    )


def atualizar_ong(id_ong, d):
    db.executar(
        """UPDATE Ong
              SET id_adm_sistema = %s, nome = %s, cnpj = %s, razao_social = %s, email = %s,
                  endereco = %s, telefone = %s, situacao_cadastro = %s
            WHERE id_ong = %s""",
        (d["id_adm_sistema"], d["nome"], d["cnpj"], d["razao_social"], d["email"], d["endereco"],
         d["telefone"], d["situacao_cadastro"], id_ong),
    )


def excluir_ong(id_ong):
    db.executar("DELETE FROM Ong WHERE id_ong = %s", (id_ong,))


# ---------------------------------------------------------------- CRUD: Parceiro
def listar_parceiros():
    return db.consultar("SELECT id_parceiro, nome, documento, tipo_parceiro FROM Parceiro ORDER BY nome")


def obter_parceiro(id_parceiro):
    return db.consultar_um(
        "SELECT id_parceiro, nome, documento, tipo_parceiro FROM Parceiro WHERE id_parceiro = %s", (id_parceiro,)
    )


def inserir_parceiro(d):
    return db.executar(
        "INSERT INTO Parceiro (documento, nome, tipo_parceiro) VALUES (%s, %s, %s)",
        (d["documento"], d["nome"], d["tipo_parceiro"]),
    )


def atualizar_parceiro(id_parceiro, d):
    db.executar(
        "UPDATE Parceiro SET documento = %s, nome = %s, tipo_parceiro = %s WHERE id_parceiro = %s",
        (d["documento"], d["nome"], d["tipo_parceiro"], id_parceiro),
    )


def excluir_parceiro(id_parceiro):
    db.executar("DELETE FROM Parceiro WHERE id_parceiro = %s", (id_parceiro,))


# -------------------------------------------------------------- CRUD: Patrocinio
def listar_patrocinios():
    return db.consultar(
        """SELECT pt.id_patrocinio, o.nome AS ong, pc.nome AS parceiro, pt.valor, pt.data, pt.tipo_apoio
             FROM Patrocinio pt
             JOIN Ong o ON o.id_ong = pt.id_ong
             JOIN Parceiro pc ON pc.id_parceiro = pt.id_parceiro
            ORDER BY pt.data DESC, pt.id_patrocinio DESC"""
    )


def obter_patrocinio(id_patrocinio):
    return db.consultar_um(
        "SELECT id_patrocinio, id_ong, id_parceiro, valor, data, tipo_apoio FROM Patrocinio WHERE id_patrocinio = %s",
        (id_patrocinio,),
    )


def inserir_patrocinio(d):
    return db.executar(
        "INSERT INTO Patrocinio (id_ong, id_parceiro, valor, data, tipo_apoio) VALUES (%s, %s, %s, %s, %s)",
        (d["id_ong"], d["id_parceiro"], d["valor"], d["data"], d["tipo_apoio"]),
    )


def atualizar_patrocinio(id_patrocinio, d):
    db.executar(
        """UPDATE Patrocinio SET id_ong = %s, id_parceiro = %s, valor = %s, data = %s, tipo_apoio = %s
            WHERE id_patrocinio = %s""",
        (d["id_ong"], d["id_parceiro"], d["valor"], d["data"], d["tipo_apoio"], id_patrocinio),
    )


def excluir_patrocinio(id_patrocinio):
    db.executar("DELETE FROM Patrocinio WHERE id_patrocinio = %s", (id_patrocinio,))


# ------------------------------------------------- Consulta 1: animais x pedidos
def consultar_animais(f):
    """Junção (Animal, Ong, pedidoAdocao) + agregação, com filtros opcionais.

    O SQL é fixo: um filtro vazio chega como NULL e a condição '%s IS NULL OR ...'
    o desativa. Assim nenhum pedaço da consulta é montado a partir da entrada.
    """
    return db.consultar(
        """SELECT a.id_animal, a.nome, a.especie, a.raca, a.status_atual, o.nome AS ong,
                  COUNT(p.id_pedido) AS total_pedidos,
                  COUNT(CASE WHEN p.status_pedido = 'Em análise' THEN 1 END) AS pedidos_em_analise
             FROM Animal a
             JOIN Ong o ON o.id_ong = a.id_ong
             LEFT JOIN pedidoAdocao p ON p.id_animal = a.id_animal
            WHERE (%s IS NULL OR a.id_ong = %s)
              AND (%s IS NULL OR a.especie = %s)
              AND (%s IS NULL OR a.status_atual = %s)
              AND (%s IS NULL OR a.nome LIKE %s)
            GROUP BY a.id_animal, a.nome, a.especie, a.raca, a.status_atual, o.nome
           HAVING COUNT(p.id_pedido) >= %s
            ORDER BY total_pedidos DESC, a.nome""",
        (f["id_ong"], f["id_ong"], f["especie"], f["especie"], f["status"], f["status"],
         f["nome_like"], f["nome_like"], f["min_pedidos"]),
    )


# ------------------------------------------ Consulta 2: atendimentos veterinários
def consultar_atendimentos(f):
    """Junção de 6 tabelas + agregação com HAVING. Período em intervalo semiaberto
    (>= início e < dia seguinte ao fim), que não perde consultas do último dia."""
    return db.consultar(
        """SELECT pv.nome AS veterinario, v.crmv, o.nome AS ong,
                  COUNT(c.id_consulta) AS consultas,
                  COUNT(DISTINCT a.id_animal) AS animais_atendidos,
                  MIN(c.data) AS primeira_consulta,
                  MAX(c.data) AS ultima_consulta
             FROM Consulta c
             JOIN Veterinario v ON v.id_pessoa = c.id_veterinario
             JOIN Pessoa pv ON pv.id_pessoa = v.id_pessoa
             JOIN Prontuario pr ON pr.id_prontuario = c.id_prontuario
             JOIN Animal a ON a.id_animal = pr.id_animal
             JOIN Ong o ON o.id_ong = a.id_ong
            WHERE (%s IS NULL OR c.id_veterinario = %s)
              AND (%s IS NULL OR a.id_ong = %s)
              AND (%s IS NULL OR c.data >= CAST(%s AS DATE))
              AND (%s IS NULL OR c.data < CAST(%s AS DATE) + INTERVAL 1 DAY)
            GROUP BY pv.id_pessoa, pv.nome, v.crmv, o.id_ong, o.nome
           HAVING COUNT(c.id_consulta) >= %s
            ORDER BY consultas DESC, pv.nome""",
        (f["id_veterinario"], f["id_veterinario"], f["id_ong"], f["id_ong"],
         f["data_ini"], f["data_ini"], f["data_fim"], f["data_fim"], f["min_consultas"]),
    )


# --------------------------------------------------------- Relatório (visão do banco)
def relatorio_ongs():
    return db.consultar(
        """SELECT ong, situacao_cadastro, total_animais, disponiveis, adotados, pedidos_em_analise,
                  pedidos_aprovados, total_patrocinio, veterinarios_ativos
             FROM vw_relatorio_ong
            ORDER BY total_patrocinio DESC, ong"""
    )


# --------------------------------------------------------------- Adoções (B1/B3)
def listar_pedidos_em_analise():
    return db.consultar(
        """SELECT p.id_pedido, p.data_pedido, a.id_animal, a.nome AS animal, a.status_atual,
                  o.nome AS ong, pe.nome AS adotante
             FROM pedidoAdocao p
             JOIN Animal a ON a.id_animal = p.id_animal
             JOIN Ong o ON o.id_ong = a.id_ong
             JOIN Pessoa pe ON pe.id_pessoa = p.id_adotante
            WHERE p.status_pedido = 'Em análise'
            ORDER BY p.data_pedido"""
    )


def listar_pedidos_decididos():
    return db.consultar(
        """SELECT p.id_pedido, p.data_decisao, a.nome AS animal, a.status_atual,
                  pe.nome AS adotante, p.status_pedido, p.parecer
             FROM pedidoAdocao p
             JOIN Animal a ON a.id_animal = p.id_animal
             JOIN Pessoa pe ON pe.id_pessoa = p.id_adotante
            WHERE p.status_pedido IN ('Aprovado', 'Recusado')
            ORDER BY p.data_decisao DESC, p.id_pedido DESC
            LIMIT 10"""
    )


def obter_pedido(id_pedido):
    return db.consultar_um(
        """SELECT p.id_pedido, p.status_pedido, p.data_pedido, a.id_animal, a.nome AS animal,
                  a.status_atual, a.id_ong, o.nome AS ong, pe.nome AS adotante
             FROM pedidoAdocao p
             JOIN Animal a ON a.id_animal = p.id_animal
             JOIN Ong o ON o.id_ong = a.id_ong
             JOIN Pessoa pe ON pe.id_pessoa = p.id_adotante
            WHERE p.id_pedido = %s""",
        (id_pedido,),
    )


def avaliadores_da_ong(id_ong):
    return [
        (r["id_pessoa"], f'{r["nome"]} ({r["cargo"]})')
        for r in db.consultar(
            """SELECT ad.id_pessoa, pe.nome, ad.cargo
                 FROM AdmOng ad JOIN Pessoa pe ON pe.id_pessoa = ad.id_pessoa
                WHERE ad.id_ong = %s ORDER BY pe.nome""",
            (id_ong,),
        )
    ]


def totais_painel():
    """Totais gerais do painel inicial, lidos da visão vw_relatorio_ong."""
    return db.consultar_um("""
        SELECT COALESCE(SUM(total_animais), 0)      AS animais,
               COALESCE(SUM(disponiveis), 0)        AS disponiveis,
               COALESCE(SUM(adotados), 0)           AS adotados,
               COALESCE(SUM(pedidos_em_analise), 0) AS pedidos_em_analise,
               COALESCE(SUM(total_patrocinio), 0)   AS patrocinio
        FROM vw_relatorio_ong
    """)
