# Aplicação PetCare (Flask)

Interface web da Etapa 2. Conecta-se ao banco `petcare_db` criado pelos scripts da pasta `sql/`.

## Como executar

### 1. Banco de dados

Com o MySQL 8.0.16 ou superior no ar, execute **nesta ordem** (a partir da raiz do repositório):

```bash
mysql -u root -p < sql/01_ddl.sql
mysql -u root -p < sql/02_carga.sql
mysql -u root -p < sql/04_views.sql
```

(`03_consultas.sql` é opcional: contém as consultas de verificação da Etapa 1.)

### 2. Aplicação

Requer Python 3.10 ou superior. A partir da raiz do repositório:

```bash
cd app
python -m venv .venv
source .venv/bin/activate        # Windows (Git Bash): source .venv/Scripts/activate
pip install -r requirements.txt
cp .env.example .env             # Windows (cmd): copy .env.example .env
```

Abra o `.env` e preencha `DB_USER`, `DB_PASSWORD` e `SECRET_KEY`. Esse arquivo **não é versionado**.

```bash
python app.py
```

Acesse http://127.0.0.1:5000.

## Telas

| Menu | O que faz |
|---|---|
| Animais, ONGs, Parceiros, Patrocínios | CRUD completo (criar, consultar, alterar, remover) |
| Adoções | Avaliar pedido: aprovar altera `pedidoAdocao`, `Animal` e `SituacaoAnimal` numa única transação |
| Animais e pedidos | Consulta parametrizada com filtros (junção + agregação) |
| Atendimentos | Consulta parametrizada com filtros de período, veterinário e ONG |
| Relatório | Totais por ONG, lidos da visão `vw_relatorio_ong` |

## Demonstração de ROLLBACK

Com `DEMO_FALHA=1` no `.env`, a tela de avaliar pedido ganha a opção **Simular falha no meio da transação**.
A falha é lançada depois que os três passos já foram executados; o `ROLLBACK` desfaz tudo e o banco permanece como estava.

## Organização do código

| Arquivo | Papel |
|---|---|
| `db.py` | Conexão, consultas parametrizadas (prepared statements) e `transacao()` |
| `repo.py` | Todos os SQLs de consulta e dos CRUDs simples (strings constantes com `%s`) |
| `servicos.py` | Operações que mudam várias tabelas na mesma transação |
| `erros.py` | Tradução dos erros do MySQL em mensagens para o usuário |
| `views_*.py` | Rotas Flask (CRUDs, consultas/relatório, adoções) |
| `templates/`, `static/` | Páginas HTML e estilo |
