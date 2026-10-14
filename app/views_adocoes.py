"""Tela da operação transacional: avaliação de pedidos de adoção (itens B1 e B3)."""
import os

from flask import Blueprint, abort, redirect, render_template, request, url_for

import repo
import servicos
from erros import tentar

bp = Blueprint("adocoes", __name__)


def _demo_falha():
    return os.environ.get("DEMO_FALHA") == "1"


@bp.get("/adocoes")
def adocoes_lista():
    return render_template(
        "adocoes.html",
        pendentes=repo.listar_pedidos_em_analise(),
        decididos=repo.listar_pedidos_decididos(),
    )


@bp.route("/adocoes/<int:pk>/avaliar", methods=["GET", "POST"])
def adocoes_avaliar(pk):
    pedido = repo.obter_pedido(pk)
    if pedido is None:
        abort(404)
    avaliadores = repo.avaliadores_da_ong(pedido["id_ong"])

    if request.method == "POST":
        decisao = request.form.get("decisao")
        parecer = request.form.get("parecer", "").strip() or None
        try:
            id_adm_ong = int(request.form.get("id_adm_ong", ""))
        except ValueError:
            id_adm_ong = None
        simular = _demo_falha() and request.form.get("simular_falha") == "1"

        mensagem_ok = "Adoção aprovada: pedido, animal e histórico atualizados juntos." \
            if decisao == "aprovar" else "Pedido recusado."
        if tentar(lambda: servicos.decidir_pedido(pk, decisao, id_adm_ong, parecer, simular), mensagem_ok):
            return redirect(url_for("adocoes.adocoes_lista"))
        pedido = repo.obter_pedido(pk)  # estado real depois de um eventual ROLLBACK

    return render_template("adocao_avaliar.html", pedido=pedido, avaliadores=avaliadores,
                           demo_falha=_demo_falha(), valores=request.form)
