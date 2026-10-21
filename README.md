# Instituto PetCare

Projeto da disciplina **Laboratório de Banco de Dados** (UCB) — projeto completo de banco de
dados, do modelo conceitual à aplicação.

## Visão geral

O Instituto PetCare é um sistema para gestão de ONGs e abrigos de animais, cobrindo o cadastro
de instituições, o resgate e acolhimento de animais, o histórico clínico (consultas, vacinas e
exames) e o fluxo completo de solicitação e avaliação de adoções.

## Tema

Gestão de ONGs de proteção e adoção animal. Cadastro de animais resgatados, controle de saúde
(prontuário, vacinas, exames), processo de adoção e patrocínio por parceiros.

## Integrantes

- Maria Eduarda Gomes da Silva
- Sarah Cruz Serpa
- Vitor Lustosa Leão Pinheiro
- Victor Gabriel Andrade

## Estrutura do repositório

```
repositorio/
├── README.md
├── docs/
│   ├── relatorio-etapa1.pdf
│   ├── mer-conceitual.pdf (+ arquivo-fonte)
│   ├── modelo-logico.pdf
│   └── dicionario-dados.pdf
├── sql/
│   ├── 01_ddl.sql
│   ├── 02_carga.sql
│   ├── 03_consultas.sql
│   ├── 04_views.sql
│   └── 05_indices.sql
|   └── 06_teste_auditoria
|   └── B5_seguranca_controle
└── app/                  (aplicação Flask — Etapa 2)
    ├── app.py
    ├── db.py
    ├── erros.py
    ├── repo.py
    ├── servicos.py
    ├── views_crud.py
    ├── views_consultas.py
    ├── views_adocoes.py
    ├── requirements.txt
    ├── .env.example
    ├── static/
    └── templates/
```

## Como executar

### Pré-requisitos

- MySQL 8.0 ou superior (testado na versão `8.0.46`)
- Cliente `mysql` na linha de comando ou MySQL Workbench
- Python 3.10 ou superior (apenas para a aplicação)

### 1. Banco de dados

Execute os scripts da pasta `sql/` nesta ordem:

| # | Script | Função |
|---|---|---|
| 1 | `01_ddl.sql` | Cria o banco `petcare_db`, as tabelas, os índices e os gatilhos |
| 2 | `02_carga.sql` | Insere os dados fictícios |
| 3 | `04_views.sql` | Cria a visão `vw_relatorio_ong`, usada pela aplicação |
| 4 | `05_indices.sql` | Cria os índices adotados após os estudos de `EXPLAIN` (B4) |
| 5 | `03_consultas.sql` | Executa as 15 consultas de verificação (pode ser rodado a qualquer momento depois do passo 2) |
| 6 | `B5_seguranca_controle` |  |
| 7 | `06_teste_auditoria` |  |

> **Atenção:** o `01_ddl.sql` começa com `DROP DATABASE IF EXISTS petcare_db;`, então o banco é apagado e recriado a cada execução. Não o execute com o banco em uso se não quiser perder os dados.

#### Pela linha de comando

A partir da raiz do repositório:

```bash
mysql -u root -p < sql/01_ddl.sql
mysql -u root -p < sql/02_carga.sql
mysql -u root -p < sql/04_views.sql
mysql -u root -p < sql/05_indices.sql
mysql -u root -p < sql/03_consultas.sql
```

#### Pelo MySQL Workbench

1. Abra uma conexão com o servidor.
2. Abra cada script em **File → Open SQL Script**.
3. Execute o script inteiro (`Ctrl+Shift+Enter`), seguindo a ordem da tabela acima, sem deixar
   nenhum trecho selecionado (o Workbench executa só a seleção, quando há uma).

### 2. Aplicação (Flask)

A aplicação (CRUD, consultas, relatório e fluxo de adoção com transação) fica na pasta `app/`.
Execute **depois** de criar o banco (passos acima).

A partir da raiz do repositório:

```bash
cd app
python -m venv .venv
```

Ative o ambiente virtual:

- Windows (PowerShell): `.\.venv\Scripts\Activate.ps1`
- Linux/macOS: `source .venv/bin/activate`

Instale as dependências e crie o arquivo de configuração:

```bash
pip install -r requirements.txt
```

- Windows: `copy .env.example .env`
- Linux/macOS: `cp .env.example .env`

Abra o arquivo `.env` e preencha:

| Variável | O que colocar |
|---|---|
| `DB_USER` / `DB_PASSWORD` | usuário e senha do seu MySQL |
| `DB_HOST` / `DB_PORT` / `DB_NAME` | normalmente `127.0.0.1`, `3306` e `petcare_db` |
| `SECRET_KEY` | qualquer texto longo e aleatório |
| `DEMO_FALHA` | `1` mostra, na tela de avaliar pedido, a opção de simular falha (demonstração de ROLLBACK); `0` desliga |

Inicie a aplicação:

```bash
python app.py
```

Abra http://127.0.0.1:5000 no navegador. Para encerrar, `Ctrl+C` no terminal.

> O arquivo `.env` contém a senha do banco e **não é versionado** (está no `.gitignore`). Nunca o envie ao GitHub.

Mais detalhes sobre a aplicação em [`app/README.md`](app/README.md).

### Problemas comuns

| Mensagem | Causa e solução |
|---|---|
| `Variável SECRET_KEY não definida` | O `.env` não existe na pasta em que o app foi iniciado. Rode `python app.py` de dentro da pasta `app` e confira o `.env`. |
| `Table '...' doesn't exist` | O banco não foi criado ou foi recriado vazio. Rode os scripts da seção 1 na ordem. |
| `Access denied` | Usuário ou senha do `.env` incorretos. |
| Erro ao ativar o `.venv` no PowerShell | Rode `Set-ExecutionPolicy -Scope Process Bypass` e tente de novo. |
