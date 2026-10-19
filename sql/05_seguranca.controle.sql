-- 1. Criação dos perfis de acessos
CREATE USER IF NOT EXISTS 'petcare_admbd'@'localhost' IDENTIFIED BY 'SenhaAdmbd@2026';
CREATE USER IF NOT EXISTS 'petcare_app'@'localhost' IDENTIFIED BY 'SenhaApp@2026';
CREATE USER IF NOT EXISTS 'petcare_auditor'@'localhost' IDENTIFIED BY 'SenhaAuditor@2026';

-- 2. Concessão dos privilégios 
GRANT ALL PRIVILEGES ON petcare_db.* TO 'petcare_admbd'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON petcare_db.* TO 'petcare_app'@'localhost';
REVOKE DROP, ALTER, CREATE ON petcare_db.* FROM 'petcare_app'@'localhost';

GRANT SELECT ON petcare_db.* TO 'petcare_auditor'@'localhost';

FLUSH PRIVILEGES;

-- 3. Criação da Visão (VIEW) de Restrição
USE petcare_db;

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
WHERE a.status_atual = 'Disponível';