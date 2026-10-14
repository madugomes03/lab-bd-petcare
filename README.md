
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
└── sql/
    ├── 01_ddl.sql
    ├── 02_carga.sql
    └── 03_consultas.sql
```

## Como executar

### Pré-requisitos

- MySQL 8.0 ou superior (testado na versão `<preencher com SELECT VERSION();>`)
- Cliente `mysql` na linha de comando ou MySQL Workbench

### Ordem de execução

Execute os scripts da pasta `sql/` nesta ordem:

| # | Script | Função |
|---|---|---|
| 1 | `01_ddl.sql` | Cria o banco `petcare_db`, as tabelas, os índices e os gatilhos |
| 2 | `02_carga.sql` | Insere os dados fictícios |
| 3 | `03_consultas.sql` | Executa as 15 consultas de verificação |

> **Atenção:** o `01_ddl.sql` começa com `DROP DATABASE IF EXISTS petcare_db;`, então o banco é apagado e recriado a cada execução.

### Pela linha de comando

A partir da raiz do repositório:

```bash
mysql -u root -p < sql/01_ddl.sql
mysql -u root -p < sql/02_carga.sql
mysql -u root -p < sql/03_consultas.sql
```

### Pelo MySQL Workbench

1. Abra uma conexão com o servidor.
2. Abra cada script em **File → Open SQL Script**.
3. Execute o script inteiro (`Ctrl+Shift+Enter`), seguindo a ordem da tabela acima.
