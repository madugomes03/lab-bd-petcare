# Instituto PetCare

Projeto da disciplina **Laboratório de Banco de Dados** (UCB, 2026/2) — projeto completo de banco
de dados, do modelo conceitual à aplicação.

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

## O que o projeto entrega

| Etapa | Artefatos | Onde está |
|---|---|---|
| 1 — Projeto e construção do banco | Escopo e regras de negócio (RN01–RN28), MER conceitual, dicionário de dados, modelo lógico, normalização, DDL, carga e 15 consultas | `docs/` e `sql/01` a `sql/03` |
| 2 — Operação, interface e desempenho | Aplicação Flask, transações e concorrência, índices, perfis de acesso e senhas com hash e sal, gatilhos de auditoria, projeto físico | `app/`, `sql/04` a `sql/06`, `sql/B5_seguranca_controle.sql` e `docs/relatorio-final.pdf` |

## Estrutura do repositório

```
repositorio/
├── README.md
├── docs/
│   ├── relatorio-final.pdf          (Etapa 1 revisada + Etapa 2)
│   ├── relatorio-etapa1.pdf
│   ├── mer-conceitual.pdf (+ arquivo-fonte)
│   ├── modelo-logico.pdf (+ arquivo-fonte .mwb)
│   └── dicionario-dados.pdf
├── sql/
│   ├── 01_ddl.sql                   (banco, tabelas, índices, gatilhos e tabela Auditoria)
│   ├── 02_carga.sql
│   ├── 03_consultas.sql
│   ├── 04_views.sql
│   ├── 05_indices.sql
│   ├── B5_seguranca_controle.sql    (perfis, GRANT/REVOKE, visões e credenciais)
│   └── 06_teste_auditoria.sql
└── app/                             (aplicação Flask — Etapa 2)
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

Execute os scripts da pasta `sql/` **nesta ordem**:

| # | Script | Função |
|---|---|---|
| 1 | `01_ddl.sql` | Cria o banco `petcare_db`, as 19 tabelas (incluindo `Auditoria`), as restrições, os índices e os gatilhos, inclusive os dois de auditoria (B6) |
| 2 | `02_carga.sql` | Insere os dados fictícios |
| 3 | `04_views.sql` | Cria a visão `vw_relatorio_ong`, usada pela aplicação |
| 4 | `05_indices.sql` | Cria os índices adotados após os estudos de `EXPLAIN` (B4) |
| 5 | `B5_seguranca_controle.sql` | Cria a tabela `CredencialAcesso` (senhas com hash e sal), as procedures de cadastro e login, as visões de restrição e os quatro perfis de acesso com `GRANT`/`REVOKE` (B5). Precisa rodar depois do `01` e do `04` |
| 6 | `06_teste_auditoria.sql` | Teste dos gatilhos de auditoria: altera o pedido 1 e o animal 1 em uma transação e mostra o resultado em `Auditoria` (B6) |
| — | `03_consultas.sql` | Executa as 15 consultas de verificação (pode ser rodado a qualquer momento depois do passo 2) |

> **Atenção:** o `01_ddl.sql` começa com `DROP DATABASE IF EXISTS petcare_db;`, então o banco é apagado e recriado a cada execução. Não o execute com o banco em uso se não quiser perder os dados. O `06_teste_auditoria.sql` modifica dados de demonstração; para voltar ao estado original, rode de novo a sequência a partir do `01_ddl.sql`.

> Os scripts usam os nomes de tabela com a mesma grafia do DDL (`Animal`, `pedidoAdocao`, `aplicacaoVacina`...). Em Linux e macOS o MySQL diferencia maiúsculas de minúsculas nesses nomes.

#### Pela linha de comando

A partir da raiz do repositório:

```bash
mysql -u root -p < sql/01_ddl.sql
mysql -u root -p < sql/02_carga.sql
mysql -u root -p < sql/04_views.sql
mysql -u root -p < sql/05_indices.sql
mysql -u root -p < sql/B5_seguranca_controle.sql
mysql -u root -p < sql/06_teste_auditoria.sql
mysql -u root -p < sql/03_consultas.sql
```

Use um usuário administrador (por exemplo, `root`): o `B5_seguranca_controle.sql` cria usuários e concede privilégios.

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
| `DB_USER` / `DB_PASSWORD` | usuário e senha do MySQL. Depois do `B5_seguranca_controle.sql`, use o perfil `petcare_app` (senha no próprio script), que é o de menor privilégio para a aplicação |
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

## Segurança e controle de acesso (B5)

O `B5_seguranca_controle.sql` cria quatro perfis de acesso, todos com host `localhost`. As senhas
são de demonstração e estão no próprio script.

| Usuário MySQL | Uso | Permissões |
|---|---|---|
| `petcare_admbd` | administrador do banco | todos os privilégios em `petcare_db` |
| `petcare_app` | aplicação Flask | `SELECT`, `INSERT` e `UPDATE` por tabela; `DELETE` só onde os CRUDs precisam (`Animal`, `Ong`, `Parceiro`, `Patrocinio`) e nos catálogos `TipoExame` e `Vacina`; `SELECT` em `vw_relatorio_ong`; `EXECUTE` nas procedures de credencial. Sem `DROP`/`ALTER`/`CREATE` e sem acesso a `Auditoria` e `CredencialAcesso` |
| `petcare_auditor` | auditoria interna (somente leitura) | `SELECT` em `Auditoria`, `SituacaoAnimal` e nas visões `vw_pedidos_auditoria`, `vw_credenciais_auditoria` e `vw_relatorio_ong`. Não lê `Pessoa` nem os dados pessoais dos adotantes |
| `petcare_publico` | visitante do site | `SELECT` apenas em `vw_animais_disponiveis` (só animais disponíveis, sem status interno nem `id_ong`) |

**Senhas da aplicação:** a tabela `CredencialAcesso` não tem coluna de senha. Guarda um sal aleatório
de 16 bytes e o hash `SHA2(CONCAT(sal, senha), 256)`. O cadastro e o login passam pelas procedures
`sp_cadastrar_credencial` e `sp_autenticar_credencial`; a aplicação não recebe acesso direto à
tabela. O script cadastra quatro contas de demonstração (`rafael.admsistema`, `sofia.admong`,
`carlos.vet` e `lucas.adotante`). Para testar o login:

```sql
CALL sp_autenticar_credencial('sofia.admong', '<senha de demonstração do script>');  -- 1 linha: confere
CALL sp_autenticar_credencial('sofia.admong', 'senhaErrada');                         -- 0 linhas
```

**Para ver a diferença entre os perfis**, conecte-se com cada usuário e tente, por exemplo,
`SELECT cpf FROM Pessoa` (o auditor e o público são negados) e `UPDATE Auditoria SET autor = 'x'`
(a aplicação é negada).

**Dados pessoais:** `Pessoa` (CPF, nome, telefone, endereço e data de nascimento) e `Parceiro`
(documento e nome, quando pessoa física). Toda a carga é fictícia.

## Auditoria (B6)

Dois gatilhos gravam na tabela `Auditoria` o autor, a data e os valores anterior e posterior, uma
linha por campo alterado:

| Gatilho | Tabela e campos auditados |
|---|---|
| `trg_animal_audita_update` | `Animal`: `status_atual` e `id_ong` |
| `trg_pedido_audita_update` | `pedidoAdocao`: `status_pedido`, `parecer` e `id_adm_ong` |

O autor vem da variável de sessão `@usuario_app`; se ela não estiver definida, o gatilho grava o
usuário do banco (`CURRENT_USER()`). O `06_teste_auditoria.sql` mostra o uso completo. Para
consultar o histórico:

```sql
SELECT tabela, id_registro, campo, valor_anterior, valor_posterior, autor, data_hora
  FROM Auditoria
 ORDER BY id_auditoria DESC;
```

## Desempenho (B4)

O `05_indices.sql` cria os dois índices adotados: `idx_consulta_data` em `Consulta(data)` e
`idx_animal_status_especie` em `Animal(status_atual, especie)`. Os estudos de `EXPLAIN` foram feitos
em tabelas de experimento com 50.000 linhas (removidas ao final) e estão no relatório final.

### Problemas comuns

| Mensagem | Causa e solução |
|---|---|
| `Variável SECRET_KEY não definida` | O `.env` não existe na pasta em que o app foi iniciado. Rode `python app.py` de dentro da pasta `app` e confira o `.env`. |
| `Table '...' doesn't exist` | O banco não foi criado ou foi recriado vazio. Rode os scripts da seção 1 na ordem. Em Linux e macOS, confira também a grafia exata do nome da tabela (`Animal`, não `animal`). |
| `Access denied` | Usuário ou senha do `.env` incorretos. Os perfis do `B5_seguranca_controle.sql` são do host `localhost`: conecte-se por `localhost` ou `127.0.0.1` na própria máquina. |
| `SELECT command denied ... vw_relatorio_ong` | O `B5_seguranca_controle.sql` não foi executado depois do `04_views.sql`, ou o `petcare_app` foi criado por uma versão antiga do script. Rode a sequência de novo a partir do `01_ddl.sql`. |
| Erro ao ativar o `.venv` no PowerShell | Rode `Set-ExecutionPolicy -Scope Process Bypass` e tente de novo. |
