"""Tradução dos erros do MySQL em mensagens compreensíveis (item B1)."""
import re

from flask import current_app, flash
from mysql.connector import Error as ErroMySQL


class ErroNegocio(Exception):
    """Regra de negócio verificada pela aplicação (a mensagem já é para o usuário)."""

_UNICOS = {
    "uq_pessoa_cpf": "Já existe uma pessoa cadastrada com este CPF.",
    "uq_parceiro_documento": "Já existe um parceiro cadastrado com este CPF/CNPJ.",
    "uq_ong_cnpj": "Já existe uma ONG cadastrada com este CNPJ.",
    "uq_veterinario_crmv": "Já existe um veterinário com este CRMV.",
    "uq_prontuario_animal": "Este animal já possui prontuário.",
}

_CHECKS = {
    "ck_animal_sexo": "Sexo inválido: use M ou F.",
    "ck_animal_status": "Situação do animal inválida.",
    "ck_ong_situacao": "Situação de cadastro da ONG inválida.",
    "ck_parceiro_tipo": "Tipo de parceiro inválido.",
    "ck_pedido_status": "Situação do pedido inválida.",
    "ck_pedido_parecer_se_recusado": "Para recusar um pedido é obrigatório informar o parecer.",
    "ck_atuacao_datas": "A data de fim da atuação não pode ser anterior à data de início.",
    "ck_situacaoanimal_datas": "A data de fim da situação não pode ser anterior à data de início.",
    "ck_situacaoanimal_status": "Situação do animal inválida.",
}

# chave estrangeira RESTRICT que impede a exclusão -> motivo
_BLOQUEIOS = {
    "fk_animal_ong": "esta ONG ainda possui animais cadastrados",
    "fk_admong_ong": "esta ONG ainda possui administradores vinculados",
    "fk_patrocinio_ong": "esta ONG ainda possui patrocínios registrados",
    "fk_patrocinio_parceiro": "este parceiro ainda possui patrocínios registrados",
    "fk_pedido_animal": "este animal possui pedidos de adoção",
    "fk_consulta_prontuario": "este animal possui consultas registradas",
    "fk_aplicvac_prontuario": "este animal possui vacinas aplicadas",
    "fk_solicitacaoexame_prontuario": "este animal possui exames solicitados",
}


def traduzir(err):
    n, msg = err.errno, (err.msg or "")

    if n == 1062:  # UNIQUE
        m = re.search(r"for key '(?:[^']*\.)?([^']+)'", msg)
        return _UNICOS.get(m.group(1) if m else "", "Já existe um registro com este valor (campo único duplicado).")

    if n in (3819, 4025):  # CHECK (3819 = MySQL, 4025 = MariaDB)
        m = re.search(r"(?:Check constraint '|CONSTRAINT `)([A-Za-z0-9_]+)", msg)
        return _CHECKS.get(m.group(1) if m else "", "Algum valor informado viola uma regra de validação do banco.")

    if n in (1451, 1217):  # FK: tentativa de excluir registro referenciado
        m = re.search(r"CONSTRAINT `([^`]+)`", msg)
        motivo = _BLOQUEIOS.get(m.group(1) if m else "", "existem registros que dependem dele")
        return f"Não é possível excluir: {motivo}."

    if n in (1452, 1216):  # FK: referência a registro inexistente
        return "O registro relacionado não existe. Confira a ONG, o parceiro ou o animal selecionado."

    if n == 1644:  # SIGNAL dos gatilhos (RN19, RN20): a mensagem já é amigável
        return msg

    if n in (1048, 1364):
        m = re.search(r"(?:Column|Field) '([^']+)'", msg)
        return f"Preencha o campo obrigatório: {m.group(1) if m else 'campo'}."

    if n == 1406:
        m = re.search(r"column '([^']+)'", msg)
        return f"O texto informado em '{m.group(1) if m else 'um campo'}' é maior do que o permitido."

    if n in (1292, 1366):
        return "Formato inválido em algum campo (use datas AAAA-MM-DD e números com ponto ou vírgula)."

    if n == 1264:
        return "Número fora do intervalo permitido para o campo."

    if n == 1213:
        return "Conflito de concorrência (deadlock): a operação foi desfeita. Tente novamente."

    if n == 1205:
        return "A operação esperou demais por um bloqueio de outro usuário e foi cancelada. Tente novamente."

    if n in (2002, 2003, 2013, 1045, 1049):
        return "Não foi possível acessar o banco de dados. Verifique se o MySQL está no ar e se o arquivo .env está correto."

    return "O banco de dados recusou a operação. Confira os dados informados e tente novamente."


def tentar(operacao, mensagem_ok):
  
    try:
        operacao()
    except ErroNegocio as e:
        flash(str(e), "erro")
        return False
    except ErroMySQL as e:
        current_app.logger.warning("MySQL errno=%s sqlstate=%s msg=%s", e.errno, e.sqlstate, e.msg)
        flash(traduzir(e), "erro")
        return False
    flash(mensagem_ok, "ok")
    return True
