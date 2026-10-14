"""Duas telas de consulta parametrizada e a tela de relatório (item B1)."""
from flask import Blueprint, render_template, request

import repo

bp = Blueprint("consultas", __name__)

STATUS_ANIMAL = [(s, s) for s in ("Tratamento", "Disponível", "Em Adoção", "Adotado", "Óbito")]


def _texto(nome):
    return (request.args.get(nome, "") or "").strip() or None


def _inteiro(nome, padrao=None):
    try:
        return int(request.args.get(nome, ""))
    except ValueError:
        return padrao


def _padrao_like(termo):
    """Monta o valor do LIKE ('%termo%') escapando curingas digitados pelo usuário.
    É um PARÂMETRO (não vira parte do SQL), então não há risco de injeção."""
    if termo is None:
        return None
    escapado = termo.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{escapado}%"


@bp.get("/consultas/animais")
def consulta_animais():
    filtros = {
        "id_ong": _inteiro("id_ong"),
        "especie": _texto("especie"),
        "status": _texto("status"),
        "nome": _texto("nome"),
        "min_pedidos": max(_inteiro("min_pedidos", 0), 0),
    }
    consulta = dict(filtros, nome_like=_padrao_like(filtros["nome"]))
    colunas = [("id_animal", "ID"), ("nome", "Animal"), ("especie", "Espécie"), ("raca", "Raça"),
               ("status_atual", "Situação"), ("ong", "ONG"), ("total_pedidos", "Pedidos"),
               ("pedidos_em_analise", "Em análise")]
    return render_template(
        "consulta_animais.html", f=filtros, colunas=colunas, linhas=repo.consultar_animais(consulta),
        ongs=repo.opcoes_ongs(), especies=[(e, e) for e in repo.listar_especies()], status=STATUS_ANIMAL,
    )


@bp.get("/consultas/atendimentos")
def consulta_atendimentos():
    filtros = {
        "id_veterinario": _inteiro("id_veterinario"),
        "id_ong": _inteiro("id_ong"),
        "data_ini": _texto("data_ini"),
        "data_fim": _texto("data_fim"),
        "min_consultas": max(_inteiro("min_consultas", 1), 0),
    }
    colunas = [("veterinario", "Veterinário"), ("crmv", "CRMV"), ("ong", "ONG"), ("consultas", "Consultas"),
               ("animais_atendidos", "Animais atendidos"), ("primeira_consulta", "Primeira"),
               ("ultima_consulta", "Última")]
    return render_template(
        "consulta_atendimentos.html", f=filtros, colunas=colunas, linhas=repo.consultar_atendimentos(filtros),
        ongs=repo.opcoes_ongs(), veterinarios=repo.opcoes_veterinarios(),
    )


@bp.get("/relatorio")
def relatorio():
    """Relatório consolidado por ONG, lido da visão vw_relatorio_ong (sql/04_views.sql)."""
    colunas = [("ong", "ONG"), ("situacao_cadastro", "Cadastro"), ("total_animais", "Animais"),
               ("disponiveis", "Disponíveis"), ("adotados", "Adotados"),
               ("pedidos_em_analise", "Pedidos em análise"), ("pedidos_aprovados", "Pedidos aprovados"),
               ("veterinarios_ativos", "Veterinários ativos"), ("total_patrocinio", "Patrocínio (R$)")]
    linhas = repo.relatorio_ongs()
    totais = {c: sum(l[c] or 0 for l in linhas) for c in
              ("total_animais", "disponiveis", "adotados", "pedidos_em_analise", "pedidos_aprovados",
               "total_patrocinio")}
    return render_template("relatorio.html", colunas=colunas, linhas=linhas, totais=totais)
