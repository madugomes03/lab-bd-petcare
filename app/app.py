"""Instituto PetCare — aplicação Flask (Etapa 2, item B1).

Executar:  flask --app app run        (ou: python app.py)
"""
import os
import secrets

from dotenv import load_dotenv
from flask import Flask, abort, render_template, request, session, url_for
from mysql.connector import Error as ErroMySQL

load_dotenv()  # lê o arquivo .env local (fora do Git) antes de importar o resto

import db  # noqa: E402
import erros  # noqa: E402
import repo  # noqa: E402
from views_adocoes import bp as bp_adocoes  # noqa: E402
from views_consultas import bp as bp_consultas  # noqa: E402
from views_crud import bp as bp_crud  # noqa: E402


def criar_app():
    app = Flask(__name__)
    chave = os.environ.get("SECRET_KEY")
    if not chave:
        raise RuntimeError("Variável SECRET_KEY não definida. Copie .env.example para .env e preencha.")
    app.secret_key = chave
    app.config.update(SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax")

    app.teardown_appcontext(db.fechar_conexao)
    app.register_blueprint(bp_crud)
    app.register_blueprint(bp_consultas)
    app.register_blueprint(bp_adocoes)

    @app.before_request
    def checar_csrf():
        """Todo POST precisa carregar o token que a sessão emitiu (proteção contra CSRF)."""
        if request.method == "POST":
            enviado = request.form.get("csrf_token", "")
            esperado = session.get("csrf_token", "")
            if not esperado or not secrets.compare_digest(enviado, esperado):
                abort(400, "Formulário expirado ou inválido. Volte, recarregue a página e tente de novo.")

    @app.context_processor
    def contexto_comum():
        if "csrf_token" not in session:
            session["csrf_token"] = secrets.token_hex(16)
        return {"csrf_token": session["csrf_token"]}

    @app.get("/")
    def inicio():
        return render_template("inicio.html", t=repo.totais_painel())

    @app.errorhandler(ErroMySQL)
    def erro_de_banco(err):
        app.logger.error("MySQL errno=%s msg=%s", err.errno, err.msg)
        return render_template("erro.html", mensagem=erros.traduzir(err)), 500

    @app.errorhandler(400)
    @app.errorhandler(404)
    def erro_http(err):
        return render_template("erro.html", mensagem=err.description), err.code

    return app


app = criar_app()

if __name__ == "__main__":
    app.run(debug=os.environ.get("FLASK_DEBUG") == "1")
