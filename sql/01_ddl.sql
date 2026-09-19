-- =====================================================================
-- 01_ddl.sql — Instituto PetCare
-- Comentários associam os principais comandos às regras de negócio
-- (RN01–RN25) do documento A1.
-- =====================================================================

DROP DATABASE IF EXISTS petcare_db;
CREATE DATABASE petcare_db CHARACTER SET utf8mb4;
USE petcare_db;

-- -----------------------------------------------------
-- Criação das Tabelas Base (Entidades Fortes)
-- -----------------------------------------------------

-- RN17: CPF de pessoa física deve ser único no sistema (UNIQUE)
CREATE TABLE Pessoa
(
    id_pessoa        INT AUTO_INCREMENT,
    cpf              CHAR(11)     NOT NULL,
    nome             VARCHAR(150) NOT NULL,
    data_nascimento  DATE         NOT NULL,
    endereco         VARCHAR(255) NOT NULL,
    telefone         VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_pessoa PRIMARY KEY (id_pessoa),
    CONSTRAINT uq_pessoa_cpf UNIQUE (cpf)  -- RN17
) ENGINE=InnoDB;

-- RN17: CPF/CNPJ de parceiro (documento) também deve ser único
CREATE TABLE Parceiro
(
    id_parceiro    INT AUTO_INCREMENT,
    documento      VARCHAR(20)  NOT NULL,
    nome           VARCHAR(150) NOT NULL,
    tipo_parceiro  VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_parceiro PRIMARY KEY (id_parceiro),
    CONSTRAINT uq_parceiro_documento UNIQUE (documento)  -- RN17
) ENGINE=InnoDB;

CREATE TABLE TipoExame
(
    id_tipoExame  INT AUTO_INCREMENT,
    nome          VARCHAR(100) NOT NULL,
    descricao     VARCHAR(255),
    CONSTRAINT pk_tipoexame PRIMARY KEY (id_tipoExame)
) ENGINE=InnoDB;

CREATE TABLE Vacina
(
    id_vacina    INT AUTO_INCREMENT,
    nome         VARCHAR(100) NOT NULL,
    fabricante   VARCHAR(100) NOT NULL,
    prevencao    VARCHAR(255) NOT NULL,
    num_dose     CHAR(5)      NOT NULL,
    CONSTRAINT pk_vacina PRIMARY KEY (id_vacina)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Subclasses da Especialização de Pessoa (t, d)
-- -----------------------------------------------------

CREATE TABLE AdmSistema
(
    id_pessoa       INT NOT NULL,
    data_Admissao   DATETIME NOT NULL,
    CONSTRAINT pk_admsistema PRIMARY KEY (id_pessoa),
    CONSTRAINT fk_admsistema_pessoa FOREIGN KEY (id_pessoa) REFERENCES Pessoa(id_pessoa)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN24: ONG só publica animais após validação institucional pelo
-- administrador do sistema — daí id_adm_sistema ser opcional (a ONG
-- existe em "Em análise" antes de ser validada)
CREATE TABLE Ong
(
    id_ong             INT AUTO_INCREMENT,
    id_adm_sistema     INT NULL,  -- RN24: opcional até a validação
    nome               VARCHAR(150) NOT NULL,
    cnpj               CHAR(14)     NOT NULL,
    razao_social       VARCHAR(150) NOT NULL,
    email              VARCHAR(100) NOT NULL,
    endereco           VARCHAR(255) NOT NULL,
    telefone           VARCHAR(20)  NOT NULL,
    data_cadastro      DATETIME     NOT NULL,
    situacao_cadastro  VARCHAR(50)  NOT NULL DEFAULT 'Em análise',  -- RN24
    CONSTRAINT pk_ong PRIMARY KEY (id_ong),
    CONSTRAINT uq_ong_cnpj UNIQUE (cnpj),
    CONSTRAINT fk_ong_admsistema FOREIGN KEY (id_adm_sistema) REFERENCES AdmSistema(id_pessoa)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN03: uma ONG pode ter vários admOng, mas cada admOng cuida de 1 ONG
CREATE TABLE AdmOng
(
    id_pessoa   INT NOT NULL,
    id_ong      INT NOT NULL,  -- RN03
    cargo       VARCHAR(100) NOT NULL,
    CONSTRAINT pk_admong PRIMARY KEY (id_pessoa),
    CONSTRAINT fk_admong_pessoa FOREIGN KEY (id_pessoa) REFERENCES Pessoa(id_pessoa)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_admong_ong FOREIGN KEY (id_ong) REFERENCES Ong(id_ong)  -- RN03
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Adotante
(
    id_pessoa       INT NOT NULL,
    data_cadastro   DATETIME NOT NULL,
    CONSTRAINT pk_adotante PRIMARY KEY (id_pessoa),
    CONSTRAINT fk_adotante_pessoa FOREIGN KEY (id_pessoa) REFERENCES Pessoa(id_pessoa)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN16: vacina só aplicada por veterinário com CRMV válido (UNIQUE)
-- RN20: veterinário pode ter um supervisor (autorrelacionamento opcional)
CREATE TABLE Veterinario
(
    id_pessoa       INT NOT NULL,
    id_supervisor   INT NULL,  -- RN20
    crmv            CHAR(15)     NOT NULL,
    especialidade   VARCHAR(100) NOT NULL,
    CONSTRAINT pk_veterinario PRIMARY KEY (id_pessoa),
    CONSTRAINT uq_veterinario_crmv UNIQUE (crmv),  -- RN16
    CONSTRAINT fk_veterinario_pessoa FOREIGN KEY (id_pessoa) REFERENCES Pessoa(id_pessoa)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_veterinario_supervisor FOREIGN KEY (id_supervisor) REFERENCES Veterinario(id_pessoa)  -- RN20
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN20: um veterinário não pode ser seu próprio supervisor.
-- Não pode ser CHECK porque id_pessoa também está em fk_veterinario_pessoa
-- com ON UPDATE CASCADE (Erro 3823 do MySQL). Resolvido via trigger.
DELIMITER $$

CREATE TRIGGER trg_veterinario_check_supervisor_insert
BEFORE INSERT ON Veterinario
FOR EACH ROW
BEGIN
    IF NEW.id_supervisor = NEW.id_pessoa THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN20: um veterinário não pode supervisionar a si mesmo';
    END IF;
END$$

CREATE TRIGGER trg_veterinario_check_supervisor_update
BEFORE UPDATE ON Veterinario
FOR EACH ROW
BEGIN
    IF NEW.id_supervisor = NEW.id_pessoa THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN20: um veterinário não pode supervisionar a si mesmo';
    END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- Entidades Dependentes
-- -----------------------------------------------------

-- RN01/RN02: animal só existe vinculado a uma ONG já cadastrada (FK/NOT NULL)
CREATE TABLE Animal
(
    id_animal        INT AUTO_INCREMENT,
    id_ong           INT NOT NULL,  -- RN01, RN02
    nome             VARCHAR(100) NOT NULL,
    especie          VARCHAR(50)  NOT NULL,
    raca             VARCHAR(50)  NOT NULL,
    sexo             CHAR(1)      NOT NULL,
    data_nascimento  DATE         NOT NULL,  -- RN19: não pode ser futura
    descricao        VARCHAR(500),
    status_atual     VARCHAR(50)  NOT NULL DEFAULT 'Tratamento',
    CONSTRAINT pk_animal PRIMARY KEY (id_animal),
    CONSTRAINT fk_animal_ong FOREIGN KEY (id_ong) REFERENCES Ong(id_ong)  -- RN01, RN02
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN19: data de nascimento do animal não pode ser futura (CHECK não é
-- permitido com CURDATE(); usamos trigger)
DELIMITER $$

CREATE TRIGGER trg_animal_check_data_nascimento_insert
BEFORE INSERT ON Animal
FOR EACH ROW
BEGIN
    IF NEW.data_nascimento > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data de nascimento do animal não pode ser futura';
    END IF;
END$$

CREATE TRIGGER trg_animal_check_data_nascimento_update
BEFORE UPDATE ON Animal
FOR EACH ROW
BEGIN
    IF NEW.data_nascimento > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data de nascimento do animal não pode ser futura';
    END IF;
END$$

DELIMITER ;

-- RN11: todo animal deve possuir prontuário criado no cadastro (1:1)
CREATE TABLE Prontuario
(
    id_prontuario   INT AUTO_INCREMENT,
    id_animal       INT NOT NULL,  -- RN11
    data_abertura   DATETIME NOT NULL,
    CONSTRAINT pk_prontuario PRIMARY KEY (id_prontuario),
    CONSTRAINT uq_prontuario_animal UNIQUE (id_animal),  -- RN11: garante 1:1
    CONSTRAINT fk_prontuario_animal FOREIGN KEY (id_animal) REFERENCES Animal(id_animal)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN12: toda mudança de situação do animal gera novo histórico
-- RN13: registro de histórico não existe solto, sem animal (FK NOT NULL)
-- Entidade fraca identificada por (id_animal, registro). "registro" NÃO
-- é AUTO_INCREMENT: o InnoDB exige que a coluna auto_increment seja a
-- 1ª da chave, e o contador precisa ser POR ANIMAL — a aplicação (ou
-- um trigger) calcula MAX(registro)+1 para aquele id_animal (RN12).
CREATE TABLE SituacaoAnimal
(
    id_animal      INT NOT NULL,  -- RN13
    registro       INT NOT NULL,
    data_registro  DATETIME     NOT NULL,
    motivo         VARCHAR(255) NOT NULL,
    status         VARCHAR(50)  NOT NULL,
    data_inicio    DATE         NOT NULL,
    data_fim       DATE,
    observacoes    VARCHAR(500),
    CONSTRAINT pk_situacaoanimal PRIMARY KEY (id_animal, registro),
    CONSTRAINT fk_situacaoanimal_animal FOREIGN KEY (id_animal) REFERENCES Animal(id_animal)  -- RN13
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN14: consulta deve estar vinculada a um veterinário E a um prontuário
CREATE TABLE Consulta
(
    id_consulta      INT AUTO_INCREMENT,
    id_prontuario    INT NOT NULL,  -- RN14
    id_veterinario   INT NOT NULL,  -- RN14
    data             DATETIME     NOT NULL,  -- RN19: não pode ser futura
    diagnostico      VARCHAR(500) NOT NULL,
    notas            VARCHAR(500),
    CONSTRAINT pk_consulta PRIMARY KEY (id_consulta),
    CONSTRAINT fk_consulta_prontuario FOREIGN KEY (id_prontuario) REFERENCES Prontuario(id_prontuario)  -- RN14
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_consulta_veterinario FOREIGN KEY (id_veterinario) REFERENCES Veterinario(id_pessoa)  -- RN14
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN19: data da consulta não pode ser futura
DELIMITER $$

CREATE TRIGGER trg_consulta_check_data_insert
BEFORE INSERT ON Consulta
FOR EACH ROW
BEGIN
    IF NEW.data > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data da consulta não pode ser futura';
    END IF;
END$$

CREATE TRIGGER trg_consulta_check_data_update
BEFORE UPDATE ON Consulta
FOR EACH ROW
BEGIN
    IF NEW.data > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data da consulta não pode ser futura';
    END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- Tabelas Associativas
-- -----------------------------------------------------

CREATE TABLE Atuacao
(
    id_atuacao      INT AUTO_INCREMENT,
    id_ong          INT NOT NULL,
    id_veterinario  INT NOT NULL,
    data_inicio     DATE NOT NULL,
    data_fim        DATE NULL,
    CONSTRAINT pk_atuacao PRIMARY KEY (id_atuacao),
    CONSTRAINT fk_atuacao_ong FOREIGN KEY (id_ong) REFERENCES Ong(id_ong)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_atuacao_veterinario FOREIGN KEY (id_veterinario) REFERENCES Veterinario(id_pessoa)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN04: patrocínio deve conter valor, data e tipo de apoio obrigatórios
-- RN05: parceiro só patrocina ONG com ambos os cadastros já existentes
-- (garantido estruturalmente pelas duas FKs abaixo)
CREATE TABLE Patrocinio
(
    id_patrocinio  INT AUTO_INCREMENT,
    id_ong         INT NOT NULL,  -- RN05
    id_parceiro    INT NOT NULL,  -- RN05
    valor          DECIMAL(10,2) NOT NULL,   -- RN04
    data           DATE  NOT NULL,        -- RN04
    tipo_apoio     VARCHAR(100) NOT NULL, -- RN04
    CONSTRAINT pk_patrocinio PRIMARY KEY (id_patrocinio),
    CONSTRAINT fk_patrocinio_ong FOREIGN KEY (id_ong) REFERENCES Ong(id_ong)  -- RN05
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_patrocinio_parceiro FOREIGN KEY (id_parceiro) REFERENCES Parceiro(id_parceiro)  -- RN05
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN18: exame deve estar vinculado a um TipoExame e a um prontuário,
-- com datas de solicitação e realização registradas
CREATE TABLE SolicitacaoExame
(
    id_solicitacao     INT AUTO_INCREMENT,
    id_prontuario      INT NOT NULL,  -- RN18
    id_tipoExame       INT NOT NULL,  -- RN18
    data_solicitacao   DATETIME NOT NULL,  -- RN18, RN19
    data_realizacao    DATETIME NULL,      -- RN18; NULL = exame ainda pendente, ou data futura agendada (ver trigger)
    resultado          VARCHAR(500),
    CONSTRAINT pk_solicitacaoexame PRIMARY KEY (id_solicitacao),
    CONSTRAINT fk_solicitacaoexame_prontuario FOREIGN KEY (id_prontuario) REFERENCES Prontuario(id_prontuario)  -- RN18
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_solicitacaoexame_tipoexame FOREIGN KEY (id_tipoExame) REFERENCES TipoExame(id_tipoExame)  -- RN18
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN19: data_solicitacao nunca pode ser futura (o pedido é sempre feito
-- "agora"). data_realizacao PODE ser futura enquanto o exame ainda está
-- agendado/pendente (resultado NULL) — a regra só passa a valer sobre
-- data_realizacao no momento em que o resultado é registrado, pois é
-- aí que o exame passa a ser um fato já ocorrido.
DELIMITER $$

CREATE TRIGGER trg_solicitacaoexame_check_datas_insert
BEFORE INSERT ON SolicitacaoExame
FOR EACH ROW
BEGIN
    IF NEW.data_solicitacao > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data de solicitação do exame não pode ser futura';
    END IF;
    IF NEW.resultado IS NOT NULL AND (NEW.data_realizacao IS NULL OR NEW.data_realizacao > NOW()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: exame com resultado precisa de data de realização válida e não futura';
    END IF;
END$$

CREATE TRIGGER trg_solicitacaoexame_check_datas_update
BEFORE UPDATE ON SolicitacaoExame
FOR EACH ROW
BEGIN
    IF NEW.data_solicitacao > NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data de solicitação do exame não pode ser futura';
    END IF;
    IF NEW.resultado IS NOT NULL AND (NEW.data_realizacao IS NULL OR NEW.data_realizacao > NOW()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: exame com resultado precisa de data de realização válida e não futura';
    END IF;
END$$

DELIMITER ;

-- RN15: aplicação de vacina deve registrar dose, lote e data (NOT NULL)
-- RN16: só veterinário cadastrado (com CRMV) pode aplicar vacina (FK)
CREATE TABLE aplicacaoVacina
(
    id_aplicacao    INT AUTO_INCREMENT,
    id_prontuario   INT NOT NULL,
    id_vacina       INT NOT NULL,
    id_veterinario  INT NOT NULL,  -- RN16
    dose            VARCHAR(50) NOT NULL,  -- RN15
    lote            CHAR(20)    NOT NULL,  -- RN15
    data_aplicacao  DATE NOT NULL,          -- RN15, RN19
    CONSTRAINT pk_aplicacaovacina PRIMARY KEY (id_aplicacao),
    CONSTRAINT fk_aplicvac_prontuario FOREIGN KEY (id_prontuario) REFERENCES Prontuario(id_prontuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_aplicvac_vacina FOREIGN KEY (id_vacina) REFERENCES Vacina(id_vacina)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_aplicvac_veterinario FOREIGN KEY (id_veterinario) REFERENCES Veterinario(id_pessoa)  -- RN16
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- RN19: data de aplicação da vacina não pode ser futura
DELIMITER $$

CREATE TRIGGER trg_aplicacaovacina_check_data_insert
BEFORE INSERT ON aplicacaoVacina
FOR EACH ROW
BEGIN
    IF NEW.data_aplicacao > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data de aplicação da vacina não pode ser futura';
    END IF;
END$$

CREATE TRIGGER trg_aplicacaovacina_check_data_update
BEFORE UPDATE ON aplicacaoVacina
FOR EACH ROW
BEGIN
    IF NEW.data_aplicacao > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN19: data de aplicação da vacina não pode ser futura';
    END IF;
END$$

DELIMITER ;

-- RN06: pedido avaliado por no máx. 1 admOng por vez (id_adm_ong opcional
--       no início, conforme RN06 — avaliação acontece depois)
-- RN08: se recusado, parecer é obrigatório (CHECK abaixo)
-- RN09: data_decisao preenchida quando aprovado/recusado (reforçar via
--       trigger/aplicação, já que o valor em si depende do momento da ação)
CREATE TABLE pedidoAdocao
(
    id_pedido       INT AUTO_INCREMENT,
    id_animal       INT NOT NULL,
    id_adotante     INT NOT NULL,  -- RN07: 1 pedido ativo por adotante (aplicação)
    id_adm_ong      INT NULL,  -- RN06
    data_pedido     DATETIME NOT NULL,
    data_decisao    DATETIME,  -- RN09
    parecer         VARCHAR(500) NULL,  -- RN08: opcional, obrigatório só se recusado
    status_pedido   VARCHAR(50)  NOT NULL DEFAULT 'Em análise',
    CONSTRAINT pk_pedidoadocao PRIMARY KEY (id_pedido),
    CONSTRAINT fk_pedido_animal FOREIGN KEY (id_animal) REFERENCES Animal(id_animal)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_adotante FOREIGN KEY (id_adotante) REFERENCES Adotante(id_pessoa)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_admong FOREIGN KEY (id_adm_ong) REFERENCES AdmOng(id_pessoa)  -- RN06
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT ck_pedido_parecer_se_recusado
        CHECK (status_pedido <> 'Recusado' OR parecer IS NOT NULL)  -- RN08
) ENGINE=InnoDB;

CREATE INDEX idx_animal_ong ON Animal(id_ong);
CREATE INDEX idx_consulta_veterinario ON Consulta(id_veterinario);
CREATE INDEX idx_pedido_animal ON pedidoAdocao(id_animal);
CREATE INDEX idx_pedido_adotante ON pedidoAdocao(id_adotante);