"""Operações de negócio que alteram várias tabelas numa única transação (itens B1 e B3)."""
import db
from erros import ErroNegocio

STATUS_INICIAL = "Tratamento"


def _definir_autor(tx, id_pessoa, nome):
    """Auditoria (B6): informa aos gatilhos QUEM está fazendo a alteração.

    Os gatilhos trg_animal_audita_update e trg_pedido_audita_update leem a variável de sessão
    @usuario_app. Há uma conexão por requisição (fechada ao final), então o valor não vaza
    para outra pessoa.
    """
    tx.executar("SET @usuario_app = %s", (f"{nome} (admOng #{id_pessoa})",))


def _registrar_mudanca_situacao(tx, id_animal, novo_status, motivo):
    """RN12: toda mudança de situação encerra o histórico aberto e cria um novo registro."""
    tx.executar(
        "UPDATE SituacaoAnimal SET data_fim = CURDATE() WHERE id_animal = %s AND data_fim IS NULL",
        (id_animal,),
    )
    proximo = tx.um(
        "SELECT COALESCE(MAX(registro), 0) + 1 AS proximo FROM SituacaoAnimal WHERE id_animal = %s",
        (id_animal,),
    )["proximo"]
    tx.executar(
        """INSERT INTO SituacaoAnimal (id_animal, registro, data_registro, motivo, status, data_inicio)
           VALUES (%s, %s, NOW(), %s, %s, CURDATE())""",
        (id_animal, proximo, motivo, novo_status),
    )


# --------------------------------------------------------------------------
# Cadastro de animal: Animal + Prontuario (RN11) + 1º registro de SituacaoAnimal (RN12)
# --------------------------------------------------------------------------
def cadastrar_animal(d):
    with db.transacao() as tx:
        ong = tx.um("SELECT id_ong FROM Ong WHERE id_ong = %s", (d["id_ong"],))
        if ong is None:
            raise ErroNegocio("Selecione a ONG responsável pelo animal (RN01).")

        # O animal nasce em 'Tratamento' (ainda não publicado), então qualquer ONG pode cadastrá-lo;
        # a exigência de ONG validada (RN24) vale na publicação — ver atualizar_animal().
        id_animal = tx.executar(
            """INSERT INTO Animal (id_ong, nome, especie, raca, sexo, data_nascimento, descricao, status_atual)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (d["id_ong"], d["nome"], d["especie"], d["raca"], d["sexo"], d["data_nascimento"],
             d["descricao"], STATUS_INICIAL),
        )
        tx.executar("INSERT INTO Prontuario (id_animal, data_abertura) VALUES (%s, NOW())", (id_animal,))
        tx.executar(
            """INSERT INTO SituacaoAnimal (id_animal, registro, data_registro, motivo, status, data_inicio)
               VALUES (%s, 1, NOW(), %s, %s, CURDATE())""",
            (id_animal, "Cadastro inicial do animal", STATUS_INICIAL),
        )
    return id_animal


def atualizar_animal(id_animal, d):
    """Edita o animal; se a situação mudou, grava também o histórico (RN12)."""
    with db.transacao() as tx:
        atual = tx.um(
            """SELECT a.status_atual, a.id_ong, o.situacao_cadastro
                 FROM Animal a JOIN Ong o ON o.id_ong = a.id_ong
                WHERE a.id_animal = %s
                  FOR UPDATE""",
            (id_animal,),
        )
        if atual is None:
            raise ErroNegocio("Animal não encontrado.")
        try:
            id_resp = int(d.get("responsavel"))
        except (TypeError, ValueError):
            id_resp = None
        resp = tx.um(
            """SELECT pe.nome FROM AdmOng ad JOIN Pessoa pe ON pe.id_pessoa = ad.id_pessoa
                WHERE ad.id_pessoa = %s AND ad.id_ong = %s""",
            (id_resp, atual["id_ong"]),
        )
        if resp is None:
            raise ErroNegocio("Selecione o administrador da ONG responsável por esta alteração (auditoria).")
        _definir_autor(tx, id_resp, resp["nome"])
        publicando = d["status_atual"] in ("Disponível", "Em Adoção")
        if publicando and atual["situacao_cadastro"] != "Validado":
            raise ErroNegocio("RN24: a ONG ainda não foi validada, então seus animais não podem ser publicados.")
        tx.executar(
            """UPDATE Animal
                  SET nome = %s, especie = %s, raca = %s, sexo = %s, data_nascimento = %s,
                      descricao = %s, status_atual = %s
                WHERE id_animal = %s""",
            (d["nome"], d["especie"], d["raca"], d["sexo"], d["data_nascimento"], d["descricao"],
             d["status_atual"], id_animal),
        )
        if d["status_atual"] != atual["status_atual"]:
            _registrar_mudanca_situacao(
                tx, id_animal, d["status_atual"], d.get("motivo_situacao") or "Alteração manual de situação"
            )


# --------------------------------------------------------------------------
# Decisão sobre um pedido de adoção — a operação transacional central
# --------------------------------------------------------------------------
def decidir_pedido(id_pedido, decisao, id_adm_ong, parecer, simular_falha=False):
    """Aprova ou recusa um pedido de adoção.

    Aprovar altera 3 tabelas na MESMA transação:
      1. pedidoAdocao   -> pedido vira 'Aprovado' (e os outros pedidos do animal viram 'Recusado')
      2. Animal         -> status_atual = 'Adotado'
      3. SituacaoAnimal -> encerra o histórico aberto e abre um novo (RN12)
    Se qualquer passo falhar, nada é gravado (ROLLBACK).
    """
    if decisao not in ("aprovar", "recusar"):
        raise ErroNegocio("Escolha aprovar ou recusar.")
    if id_adm_ong is None:
        raise ErroNegocio("Selecione o administrador da ONG que avalia o pedido (RN06).")

    with db.transacao() as tx:
        # Trava as linhas do pedido e do animal: duas aprovações simultâneas do mesmo
        # animal ficam em fila (a segunda só prossegue depois do COMMIT da primeira).
        pedido = tx.um(
            """SELECT p.status_pedido, a.id_animal, a.status_atual, a.id_ong
                 FROM pedidoAdocao p
                 JOIN Animal a ON a.id_animal = p.id_animal
                WHERE p.id_pedido = %s
                  FOR UPDATE""",
            (id_pedido,),
        )
        if pedido is None:
            raise ErroNegocio("Pedido não encontrado.")
        if pedido["status_pedido"] != "Em análise":
            raise ErroNegocio("Este pedido já foi decidido por outra pessoa.")

        avaliador = tx.um(
            """SELECT ad.id_ong, pe.nome FROM AdmOng ad JOIN Pessoa pe ON pe.id_pessoa = ad.id_pessoa
                WHERE ad.id_pessoa = %s""",
            (id_adm_ong,),
        )
        if avaliador is None or avaliador["id_ong"] != pedido["id_ong"]:
            raise ErroNegocio("RN06/RN21: o avaliador precisa ser administrador da ONG responsável pelo animal.")
        _definir_autor(tx, id_adm_ong, avaliador["nome"])  # autor da auditoria (B6)

        if decisao == "recusar":
            # RN08 (parecer obrigatório) é garantida pelo CHECK do banco: se o parecer vier
            # vazio, o MySQL recusa e erros.traduzir() mostra a mensagem da regra.
            tx.executar(
                """UPDATE pedidoAdocao
                      SET status_pedido = 'Recusado', id_adm_ong = %s, data_decisao = NOW(), parecer = %s
                    WHERE id_pedido = %s""",
                (id_adm_ong, parecer, id_pedido),
            )
            return

        if pedido["status_atual"] not in ("Disponível", "Em Adoção"):
            raise ErroNegocio("RN10: só é possível aprovar adoção de animal 'Disponível' ou 'Em Adoção'.")

        id_animal = pedido["id_animal"]
        tx.executar(
            """UPDATE pedidoAdocao
                  SET status_pedido = 'Aprovado', id_adm_ong = %s, data_decisao = NOW(), parecer = %s
                WHERE id_pedido = %s""",
            (id_adm_ong, parecer, id_pedido),
        )
        tx.executar("UPDATE Animal SET status_atual = 'Adotado' WHERE id_animal = %s", (id_animal,))
        _registrar_mudanca_situacao(tx, id_animal, "Adotado", f"Adoção aprovada (pedido #{id_pedido})")

        if simular_falha:
            # Falha provocada de propósito para a demonstração de ROLLBACK (item B3):
            # os 3 passos acima já foram executados, mas serão desfeitos.
            raise ErroNegocio(
                "Falha simulada no meio da transação: o pedido, o animal e o histórico já tinham sido "
                "alterados, mas tudo foi desfeito (ROLLBACK). Nada foi gravado."
            )

        tx.executar(
            """UPDATE pedidoAdocao
                  SET status_pedido = 'Recusado', id_adm_ong = %s, data_decisao = NOW(),
                      parecer = 'Animal adotado em outro pedido'
                WHERE id_animal = %s AND id_pedido <> %s AND status_pedido = 'Em análise'""",
            (id_adm_ong, id_animal, id_pedido),
        )
