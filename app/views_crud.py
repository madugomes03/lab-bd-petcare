"""Os quatro CRUDs do item B1: Animal, ONG, Parceiro e Patrocínio."""
from flask import Blueprint, abort, redirect, render_template, request, url_for

import repo
import servicos
from erros import tentar

bp = Blueprint("crud", __name__)

SEXOS = [("M", "Macho"), ("F", "Fêmea")]
STATUS_ANIMAL = [(s, s) for s in ("Tratamento", "Disponível", "Em Adoção", "Adotado", "Óbito")]
SITUACOES_ONG = [(s, s) for s in ("Em análise", "Validado", "Recusado")]
TIPOS_PARCEIRO = [(s, s) for s in ("Empresa", "Pessoa Física", "ONG Parceira")]


def campo(nome, rotulo, tipo="text", obrig=False, opcoes=None, maxlength=None, **extra):
    return {"nome": nome, "rotulo": rotulo, "tipo": tipo, "obrig": obrig, "opcoes": opcoes,
            "maxlength": maxlength, **extra}


def ler_form(campos):
    """Lê do formulário só os campos declarados; texto vazio vira None (NULL no banco)."""
    return {c["nome"]: (request.form.get(c["nome"], "").strip() or None) for c in campos}


def _form_pagina(titulo, base, campos, valores, edicao):
    return render_template("crud_form.html", titulo=titulo, base=base, campos=campos, valores=valores, edicao=edicao)


# ====================================================================== Animal
def _campos_animal(edicao):
    campos = []
    if not edicao:
        campos.append(campo("id_ong", "ONG responsável", "select", True, repo.opcoes_ongs()))
    campos += [
        campo("nome", "Nome", obrig=True, maxlength=100),
        campo("especie", "Espécie", obrig=True, maxlength=50),
        campo("raca", "Raça", obrig=True, maxlength=50),
        campo("sexo", "Sexo", "select", True, SEXOS),
        campo("data_nascimento", "Data de nascimento", "date", True),
        campo("descricao", "Descrição", "textarea", maxlength=500),
    ]
    if edicao:
        campos += [
            campo("status_atual", "Situação", "select", True, STATUS_ANIMAL),
            campo("motivo_situacao", "Motivo da mudança de situação (se alterar)", maxlength=255),
        ]
    return campos


@bp.get("/animais")
def animais_lista():
    colunas = [("id_animal", "ID"), ("nome", "Nome"), ("especie", "Espécie"), ("raca", "Raça"), ("sexo", "Sexo"),
               ("data_nascimento", "Nascimento"), ("status_atual", "Situação"), ("ong", "ONG")]
    return render_template("crud_lista.html", titulo="Animais", base="animais", pk="id_animal",
                           colunas=colunas, linhas=repo.listar_animais(), historico=True)


@bp.route("/animais/novo", methods=["GET", "POST"])
def animais_novo():
    campos = _campos_animal(False)
    if request.method == "POST":
        dados = ler_form(campos)
        if tentar(lambda: servicos.cadastrar_animal(dados),
                  "Animal cadastrado com prontuário e histórico inicial (RN11, RN12)."):
            return redirect(url_for("crud.animais_lista"))
        return _form_pagina("Novo animal", "animais", campos, request.form, False)
    return _form_pagina("Novo animal", "animais", campos, {}, False)


@bp.route("/animais/<int:pk>/editar", methods=["GET", "POST"])
def animais_editar(pk):
    animal = repo.obter_animal(pk)
    if animal is None:
        abort(404)
    campos = _campos_animal(True)
    if request.method == "POST":
        dados = ler_form(campos)
        if tentar(lambda: servicos.atualizar_animal(pk, dados), "Animal atualizado."):
            return redirect(url_for("crud.animais_lista"))
        return _form_pagina("Editar animal", "animais", campos, request.form, True)
    return _form_pagina("Editar animal", "animais", campos, animal, True)


@bp.post("/animais/<int:pk>/excluir")
def animais_excluir(pk):
    tentar(lambda: repo.excluir_animal(pk), "Animal excluído.")
    return redirect(url_for("crud.animais_lista"))


@bp.get("/animais/<int:pk>/historico")
def animais_historico(pk):
    animal = repo.obter_animal(pk)
    if animal is None:
        abort(404)
    colunas = [("registro", "Registro"), ("data_registro", "Registrado em"), ("status", "Situação"),
               ("motivo", "Motivo"), ("data_inicio", "Início"), ("data_fim", "Fim")]
    return render_template("historico.html", animal=animal, colunas=colunas, linhas=repo.historico_animal(pk))


# ========================================================================= ONG
def _campos_ong():
    return [
        campo("nome", "Nome fantasia", obrig=True, maxlength=150),
        campo("razao_social", "Razão social", obrig=True, maxlength=150),
        campo("cnpj", "CNPJ (14 dígitos)", obrig=True, maxlength=14),
        campo("email", "E-mail", "email", True, maxlength=100),
        campo("telefone", "Telefone", obrig=True, maxlength=20),
        campo("endereco", "Endereço", obrig=True, maxlength=255),
        campo("situacao_cadastro", "Situação do cadastro", "select", True, SITUACOES_ONG),
        campo("id_adm_sistema", "Validado por (administrador do sistema)", "select", False, repo.opcoes_adm_sistema()),
    ]


@bp.get("/ongs")
def ongs_lista():
    colunas = [("id_ong", "ID"), ("nome", "Nome"), ("cnpj", "CNPJ"), ("email", "E-mail"),
               ("telefone", "Telefone"), ("situacao_cadastro", "Situação")]
    return render_template("crud_lista.html", titulo="ONGs", base="ongs", pk="id_ong",
                           colunas=colunas, linhas=repo.listar_ongs())


@bp.route("/ongs/novo", methods=["GET", "POST"])
def ongs_novo():
    campos = _campos_ong()
    if request.method == "POST":
        dados = ler_form(campos)
        if tentar(lambda: repo.inserir_ong(dados), "ONG cadastrada."):
            return redirect(url_for("crud.ongs_lista"))
        return _form_pagina("Nova ONG", "ongs", campos, request.form, False)
    return _form_pagina("Nova ONG", "ongs", campos, {"situacao_cadastro": "Em análise"}, False)


@bp.route("/ongs/<int:pk>/editar", methods=["GET", "POST"])
def ongs_editar(pk):
    ong = repo.obter_ong(pk)
    if ong is None:
        abort(404)
    campos = _campos_ong()
    if request.method == "POST":
        dados = ler_form(campos)
        if tentar(lambda: repo.atualizar_ong(pk, dados), "ONG atualizada."):
            return redirect(url_for("crud.ongs_lista"))
        return _form_pagina("Editar ONG", "ongs", campos, request.form, True)
    return _form_pagina("Editar ONG", "ongs", campos, ong, True)


@bp.post("/ongs/<int:pk>/excluir")
def ongs_excluir(pk):
    tentar(lambda: repo.excluir_ong(pk), "ONG excluída.")
    return redirect(url_for("crud.ongs_lista"))


# ===================================================================== Parceiro
def _campos_parceiro():
    return [
        campo("nome", "Nome", obrig=True, maxlength=150),
        campo("documento", "CPF ou CNPJ (só números)", obrig=True, maxlength=20),
        campo("tipo_parceiro", "Tipo de parceiro", "select", True, TIPOS_PARCEIRO),
    ]


@bp.get("/parceiros")
def parceiros_lista():
    colunas = [("id_parceiro", "ID"), ("nome", "Nome"), ("documento", "Documento"), ("tipo_parceiro", "Tipo")]
    return render_template("crud_lista.html", titulo="Parceiros", base="parceiros", pk="id_parceiro",
                           colunas=colunas, linhas=repo.listar_parceiros())


@bp.route("/parceiros/novo", methods=["GET", "POST"])
def parceiros_novo():
    campos = _campos_parceiro()
    if request.method == "POST":
        dados = ler_form(campos)
        if tentar(lambda: repo.inserir_parceiro(dados), "Parceiro cadastrado."):
            return redirect(url_for("crud.parceiros_lista"))
        return _form_pagina("Novo parceiro", "parceiros", campos, request.form, False)
    return _form_pagina("Novo parceiro", "parceiros", campos, {}, False)


@bp.route("/parceiros/<int:pk>/editar", methods=["GET", "POST"])
def parceiros_editar(pk):
    parceiro = repo.obter_parceiro(pk)
    if parceiro is None:
        abort(404)
    campos = _campos_parceiro()
    if request.method == "POST":
        dados = ler_form(campos)
        if tentar(lambda: repo.atualizar_parceiro(pk, dados), "Parceiro atualizado."):
            return redirect(url_for("crud.parceiros_lista"))
        return _form_pagina("Editar parceiro", "parceiros", campos, request.form, True)
    return _form_pagina("Editar parceiro", "parceiros", campos, parceiro, True)


@bp.post("/parceiros/<int:pk>/excluir")
def parceiros_excluir(pk):
    tentar(lambda: repo.excluir_parceiro(pk), "Parceiro excluído.")
    return redirect(url_for("crud.parceiros_lista"))


# =================================================================== Patrocínio
def _campos_patrocinio():
    return [
        campo("id_ong", "ONG patrocinada", "select", True, repo.opcoes_ongs()),
        campo("id_parceiro", "Parceiro", "select", True, repo.opcoes_parceiros()),
        campo("valor", "Valor (R$)", "text", True, maxlength=13, inputmode="decimal"),
        campo("data", "Data", "date", True),
        campo("tipo_apoio", "Tipo de apoio", obrig=True, maxlength=100),
    ]


def _ler_patrocinio(campos):
    dados = ler_form(campos)
    if dados["valor"] and "," in dados["valor"]:
        # formato brasileiro: 1.500,50 -> 1500.50
        dados["valor"] = dados["valor"].replace(".", "").replace(",", ".")
    return dados


@bp.get("/patrocinios")
def patrocinios_lista():
    colunas = [("id_patrocinio", "ID"), ("ong", "ONG"), ("parceiro", "Parceiro"), ("valor", "Valor (R$)"),
               ("data", "Data"), ("tipo_apoio", "Tipo de apoio")]
    return render_template("crud_lista.html", titulo="Patrocínios", base="patrocinios", pk="id_patrocinio",
                           colunas=colunas, linhas=repo.listar_patrocinios())


@bp.route("/patrocinios/novo", methods=["GET", "POST"])
def patrocinios_novo():
    campos = _campos_patrocinio()
    if request.method == "POST":
        dados = _ler_patrocinio(campos)
        if tentar(lambda: repo.inserir_patrocinio(dados), "Patrocínio registrado."):
            return redirect(url_for("crud.patrocinios_lista"))
        return _form_pagina("Novo patrocínio", "patrocinios", campos, request.form, False)
    return _form_pagina("Novo patrocínio", "patrocinios", campos, {}, False)


@bp.route("/patrocinios/<int:pk>/editar", methods=["GET", "POST"])
def patrocinios_editar(pk):
    patrocinio = repo.obter_patrocinio(pk)
    if patrocinio is None:
        abort(404)
    campos = _campos_patrocinio()
    if request.method == "POST":
        dados = _ler_patrocinio(campos)
        if tentar(lambda: repo.atualizar_patrocinio(pk, dados), "Patrocínio atualizado."):
            return redirect(url_for("crud.patrocinios_lista"))
        return _form_pagina("Editar patrocínio", "patrocinios", campos, request.form, True)
    return _form_pagina("Editar patrocínio", "patrocinios", campos, patrocinio, True)


@bp.post("/patrocinios/<int:pk>/excluir")
def patrocinios_excluir(pk):
    tentar(lambda: repo.excluir_patrocinio(pk), "Patrocínio excluído.")
    return redirect(url_for("crud.patrocinios_lista"))
