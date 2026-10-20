-- =====================================================================

-- B5_seguranca.controle.sql - Instituto PetCare

-- B5: Segurança e controle de acesso

-- =====================================================================

USE petcare_db;



-- ---------------------------------------------------------------------

-- Criação dos perfis de acesso (mínimo exigido: 3)

--    admbd = administrador | app = aplicação | auditor = auditoria

--    publico = visitante do site



CREATE USER IF NOT EXISTS 'petcare_admbd'@'localhost'    IDENTIFIED BY 'SenhaAdmbd@2026';

CREATE USER IF NOT EXISTS 'petcare_app'@'localhost'      IDENTIFIED BY 'SenhaApp@2026';

CREATE USER IF NOT EXISTS 'petcare_auditor'@'localhost'  IDENTIFIED BY 'SenhaAuditor@2026';

CREATE USER IF NOT EXISTS 'petcare_publico'@'localhost'  IDENTIFIED BY 'SenhaPublico@2026';



-- Limpeza: remove privilégios de uma execução anterior, para que o menor privilégio valha de fato.

-- O privilégio no nível do banco NÃO é reduzido por REVOKE em tabela.



REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'petcare_app'@'localhost';

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'petcare_auditor'@'localhost';

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'petcare_publico'@'localhost';



-- ---------------------------------------------------------------------

-- Senhas com HASH + SAL (nunca em texto claro)

-- Tabela que guarda SÓ o sal e o hash: não existe coluna de senha.

CREATE TABLE IF NOT EXISTS CredencialAcesso

(

    id_pessoa      INT          NOT NULL,

    login          VARCHAR(100) NOT NULL,

    salt           CHAR(32)     NOT NULL,   -- [B5.3] SAL: 16 bytes aleatórios em hexadecimal

    senha_hash     CHAR(64)     NOT NULL,   -- [B5.3] HASH: SHA-256 em hexadecimal

    data_cadastro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_credencialacesso PRIMARY KEY (id_pessoa),

    CONSTRAINT uq_credencialacesso_login UNIQUE (login),

    CONSTRAINT fk_credencialacesso_pessoa FOREIGN KEY (id_pessoa) REFERENCES Pessoa(id_pessoa)

        ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB;



DROP PROCEDURE IF EXISTS sp_cadastrar_credencial;

DROP PROCEDURE IF EXISTS sp_autenticar_credencial;



DELIMITER $$



-- CADASTRO: gera um sal aleatório por usuário e grava SHA2(sal + senha)

CREATE PROCEDURE sp_cadastrar_credencial(

    IN p_id_pessoa INT,

    IN p_login     VARCHAR(100),

    IN p_senha     VARCHAR(100)

)

BEGIN

    DECLARE v_salt CHAR(32);



    IF CHAR_LENGTH(p_senha) < 8 THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT = 'Senha deve ter no mínimo 8 caracteres';

    END IF;



    SET v_salt = HEX(RANDOM_BYTES(16));                       -- sal



    INSERT INTO CredencialAcesso (id_pessoa, login, salt, senha_hash)

    VALUES (p_id_pessoa, p_login, v_salt,

            SHA2(CONCAT(v_salt, p_senha), 256));              -- hash

END$$



-- LOGIN: recalcula o hash com o sal gravado e compara. Devolve a pessoa se confere, devolve 0 linhas caso contrário.

CREATE PROCEDURE sp_autenticar_credencial(

    IN p_login VARCHAR(100),

    IN p_senha VARCHAR(100)

)

BEGIN

    SELECT id_pessoa, login

    FROM CredencialAcesso

    WHERE login = p_login

      AND senha_hash = SHA2(CONCAT(salt, p_senha), 256);

END$$



DELIMITER ;



-- Contas de demonstração, cadastradas já com hash e sal (nenhuma senha

-- fica gravada). Senhas só para o trabalho; em produção não ficam no script.

-- O login 'sofia.admong' é o mesmo usado em @usuario_app no teste de auditoria (B6).

DELETE FROM CredencialAcesso

 WHERE login IN ('rafael.admsistema', 'sofia.admong', 'carlos.vet', 'lucas.adotante');



CALL sp_cadastrar_credencial(1, 'rafael.admsistema', 'Demo@2026!');

CALL sp_cadastrar_credencial(3, 'sofia.admong',      'Demo@2026!');

CALL sp_cadastrar_credencial(9, 'carlos.vet',        'Demo@2026!');

CALL sp_cadastrar_credencial(6, 'lucas.adotante',    'Demo@2026!');



-- ---------------------------------------------------------------------

-- Visões de restrição

-- Restringe LINHAS e COLUNAS: só animais disponíveis, sem status interno nem id_ong. Perfil que usa: petcare_publico.

CREATE OR REPLACE VIEW vw_animais_disponiveis AS

SELECT

    a.id_animal,

    o.nome AS nome_ong,

    a.nome AS nome_animal,

    a.especie,

    a.raca,

    a.sexo,

    a.data_nascimento,

    a.descricao

FROM Animal a

JOIN Ong o ON a.id_ong = o.id_ong

WHERE a.status_atual = 'Disponível';                      -- restrição de LINHAS



-- Restringe COLUNAS: pedidos de adoção sem nenhum dado pessoal do adotante. Perfil que usa: petcare_auditor.

-- Serve para conferir quem decidiu e quando (RN06, RN08, RN21).

-- auditor não vê nome, CPF, endereço nem telefone de adotante.

CREATE OR REPLACE VIEW vw_pedidos_auditoria AS

SELECT

    id_pedido,

    id_animal,

    id_adotante,

    id_adm_ong,

    data_pedido,

    data_decisao,

    status_pedido,

    parecer

FROM pedidoAdocao;



-- Restringe COLUNAS: credenciais sem salt nem senha_hash.

-- Perfil que usa: petcare_auditor.

-- [B5.4-cuidado] nem o auditor enxerga o hash e o sal das senhas.

CREATE OR REPLACE VIEW vw_credenciais_auditoria AS

SELECT id_pessoa, login, data_cadastro

FROM CredencialAcesso;



-- ---------------------------------------------------------------------

-- GRANT e REVOKE (menor privilégio), perfil a perfil

-- petcare_admbd: administrador do banco (único com DDL, backup e exclusões de histórico / pedidos de eliminação de dados pessoais).

GRANT ALL PRIVILEGES ON petcare_db.* TO 'petcare_admbd'@'localhost';



-- petcare_app: só DML, tabela a tabela, sem DROP/ALTER/CREATE e sem acesso a Auditoria nem a CredencialAcesso.

-- GRANT: concede o conjunto completo de DML em cada tabela.



GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Pessoa          TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Parceiro        TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.TipoExame       TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Vacina          TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.AdmSistema      TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Ong             TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.AdmOng          TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Adotante        TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Veterinario     TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Animal          TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Prontuario      TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.SituacaoAnimal  TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Consulta        TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Atuacao         TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.Patrocinio      TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.SolicitacaoExame TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.aplicacaoVacina TO 'petcare_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.pedidoAdocao    TO 'petcare_app'@'localhost';



-- REVOKE: retira o DELETE onde apagar quebraria o histórico.

-- Exclusão de dados pessoais a pedido do titular fica só com o admbd.



REVOKE DELETE ON petcare_db.Pessoa          FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.AdmSistema      FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Ong             FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.AdmOng          FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Veterinario     FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Animal          FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Prontuario      FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.SituacaoAnimal  FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Consulta        FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Atuacao         FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.Patrocinio      FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.SolicitacaoExame FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.aplicacaoVacina FROM 'petcare_app'@'localhost';

REVOKE DELETE ON petcare_db.pedidoAdocao    FROM 'petcare_app'@'localhost';



-- Cadastro e login só pelas procedures

-- A aplicação NÃO recebe privilégio algum sobre CredencialAcesso



GRANT EXECUTE ON PROCEDURE petcare_db.sp_cadastrar_credencial  TO 'petcare_app'@'localhost';

GRANT EXECUTE ON PROCEDURE petcare_db.sp_autenticar_credencial TO 'petcare_app'@'localhost';



-- petcare_auditor: somente leitura, apenas o que a auditoria precisa

-- usa as visões de coluna restrita.

GRANT SELECT ON petcare_db.Auditoria                 TO 'petcare_auditor'@'localhost';

GRANT SELECT ON petcare_db.vw_pedidos_auditoria      TO 'petcare_auditor'@'localhost';

GRANT SELECT ON petcare_db.vw_credenciais_auditoria  TO 'petcare_auditor'@'localhost';

GRANT SELECT ON petcare_db.vw_relatorio_ong          TO 'petcare_auditor'@'localhost';

GRANT SELECT ON petcare_db.SituacaoAnimal            TO 'petcare_auditor'@'localhost';



-- petcare_publico: visitante do site; enxerga APENAS a visão de animais disponíveis, nenhuma tabela base.



GRANT SELECT ON petcare_db.vw_animais_disponiveis    TO 'petcare_publico'@'localhost';



-- ---------------------------------------------------------------------

-- Verificação (evidências para o relatório)

-- Prova GRANT/REVOKE e menor privilégio de cada perfil (print):

SHOW GRANTS FOR 'petcare_admbd'@'localhost';

SHOW GRANTS FOR 'petcare_app'@'localhost';

SHOW GRANTS FOR 'petcare_auditor'@'localhost';

SHOW GRANTS FOR 'petcare_publico'@'localhost';



-- Prova que só hash e sal ficam gravados (nenhuma senha legível):

SELECT id_pessoa, login, salt, senha_hash FROM CredencialAcesso;



-- Prova do login: certa devolve 1 linha, errada devolve 0

CALL sp_autenticar_credencial('sofia.admong', 'Demo@2026!');

CALL sp_autenticar_credencial('sofia.admong', 'senhaErrada'); 
