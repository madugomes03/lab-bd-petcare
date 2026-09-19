-- 03_consultas.sql - Instituto PetCare
-- Consultas de verificação do banco de dados
-- ============================================================

USE petcare_db;

-- ============================================================
-- CONSULTA 01 - BÁSICA
-- Pergunta de negócio:
-- Quais animais estão atualmente disponíveis para adoção?

SELECT id_animal, nome, especie, raca, status_atual
FROM Animal
WHERE status_atual = 'Disponível'
ORDER BY nome;

-- ============================================================
-- CONSULTA 02 - BÁSICA
-- Pergunta de negócio:
-- Quais pessoas cadastradas possuem nome iniciado pela letra M?

SELECT id_pessoa, nome, telefone
FROM Pessoa
WHERE nome LIKE 'M%'
ORDER BY nome;

-- ============================================================
-- CONSULTA 03 - BÁSICA
-- Pergunta de negócio:
-- Quais consultas veterinárias foram realizadas em um determinado período?

SELECT id_consulta, id_prontuario, id_veterinario, data, diagnostico
FROM Consulta
WHERE data BETWEEN '2026-01-01' AND '2026-06-30'
ORDER BY data;

-- ============================================================
-- CONSULTA 04 - BÁSICA
-- Pergunta de negócio:
-- Quais animais cadastrados são cães ou gatos?

SELECT id_animal, nome, especie, raca, status_atual
FROM Animal
WHERE especie IN ('Cachorro', 'Gato')
ORDER BY especie, nome;

-- ============================================================
-- CONSULTA 05 - BÁSICA
-- Pergunta de negócio:
-- Quais pedidos de adoção ainda não possuem uma data de decisão?

SELECT id_pedido, id_animal, id_adotante, data_pedido, data_decisao, status_pedido
FROM pedidoAdocao
WHERE data_decisao IS NULL
ORDER BY data_pedido;

-- ============================================================
-- CONSULTA 06 - JUNÇÃO
-- Pergunta de negócio:
-- Quais são os animais cadastrados e qual ONG é responsável por cada um?

SELECT 
    a.id_animal,
    a.nome AS animal,
    a.especie,
    o.nome AS ong
FROM Animal a
INNER JOIN Ong o ON a.id_ong = o.id_ong
ORDER BY a.nome;

-- ============================================================
-- CONSULTA 07 - JUNÇÃO COM 3 TABELAS
-- Pergunta de negócio:
-- Quais consultas veterinárias foram realizadas, mostrando
-- o animal atendido, o veterinário responsável, a data e o diagnóstico?

SELECT
    a.nome AS animal,
    p.nome AS veterinario,
    c.data,
    c.diagnostico
FROM Consulta c
INNER JOIN Prontuario pr ON c.id_prontuario = pr.id_prontuario
INNER JOIN Animal a ON pr.id_animal = a.id_animal
INNER JOIN Veterinario v ON c.id_veterinario = v.id_pessoa
INNER JOIN Pessoa p ON v.id_pessoa = p.id_pessoa
ORDER BY c.data;

-- ============================================================
-- CONSULTA 08 - LEFT JOIN
-- Pergunta de negócio:
-- Quais animais estão cadastrados e quantos pedidos de adoção
-- cada um recebeu, incluindo os que não receberam nenhum?

SELECT
    a.id_animal,
    a.nome AS animal,
    COUNT(p.id_pedido) AS quantidade_pedidos
FROM Animal a
LEFT JOIN pedidoAdocao p ON a.id_animal = p.id_animal
GROUP BY a.id_animal, a.nome
ORDER BY quantidade_pedidos DESC;

-- ============================================================
-- CONSULTA 09 - AGREGAÇÃO COM GROUP BY E HAVING
-- Pergunta de negócio:
-- Quais veterinários realizaram mais de 5 consultas?

SELECT
    p.id_pessoa,
    p.nome AS veterinario,
    COUNT(c.id_consulta) AS quantidade_consultas
FROM Veterinario v
INNER JOIN Pessoa p ON v.id_pessoa = p.id_pessoa
INNER JOIN Consulta c ON v.id_pessoa = c.id_veterinario
GROUP BY p.id_pessoa, p.nome
HAVING COUNT(c.id_consulta) > 5
ORDER BY quantidade_consultas DESC;

-- ============================================================
-- CONSULTA 10 - JUNÇÃO E AGREGAÇÃO
-- Pergunta de negócio:
-- Quantos animais cada ONG abriga atualmente?

SELECT
    o.id_ong,
    o.nome AS ong,
    COUNT(a.id_animal) AS quantidade_animais
FROM Ong o
LEFT JOIN Animal a ON o.id_ong = a.id_ong
GROUP BY o.id_ong, o.nome
ORDER BY quantidade_animais DESC;

-- ============================================================
-- CONSULTA 11 - AVANÇADA (EXISTS)
-- Pergunta de negócio:
-- Quais animais já possuem pelo menos um pedido de adoção registrado?

SELECT
    a.id_animal,
    a.nome,
    a.especie,
    a.status_atual
FROM Animal a
WHERE EXISTS (
    SELECT 1
    FROM pedidoAdocao p
    WHERE p.id_animal = a.id_animal
)
ORDER BY a.nome;

-- ============================================================
-- CONSULTA 12 - AVANÇADA (SUBCONSULTA CORRELACIONADA)
-- Pergunta de negócio:
-- Quais consultas foram realizadas na data mais recente
-- de cada prontuário?

SELECT
    c.id_consulta,
    c.id_prontuario,
    c.data,
    c.diagnostico
FROM Consulta c
WHERE c.data = (
    SELECT MAX(c2.data)
    FROM Consulta c2
    WHERE c2.id_prontuario = c.id_prontuario
)
ORDER BY c.id_prontuario;

-- ============================================================
-- CONSULTA 13 - AVANÇADA
-- Pergunta de negócio:
-- Quais animais disponíveis para adoção ainda não receberam
-- nenhum pedido de adoção?

SELECT
    a.id_animal,
    a.nome,
    a.especie,
    a.raca
FROM Animal a
WHERE a.status_atual = 'Disponível'
AND NOT EXISTS (
    SELECT 1
    FROM pedidoAdocao p
    WHERE p.id_animal = a.id_animal
)
ORDER BY a.nome;

-- ============================================================
-- CONSULTA 14 - AVANÇADA
-- Pergunta de negócio:
-- Quais animais já receberam pelo menos uma aplicação de vacina?

SELECT DISTINCT
    a.id_animal,
    a.nome,
    a.especie,
    a.raca
FROM Animal a
INNER JOIN Prontuario p ON a.id_animal = p.id_animal
INNER JOIN aplicacaoVacina av ON p.id_prontuario = av.id_prontuario
ORDER BY a.nome;

-- ============================================================
-- CONSULTA 15 - AVANÇADA
-- Pergunta de negócio:
-- Quais animais disponíveis para adoção já passaram
-- por pelo menos uma consulta veterinária?

SELECT DISTINCT
    a.id_animal,
    a.nome,
    a.especie,
    a.raca,
    a.status_atual
FROM Animal a
INNER JOIN Prontuario p ON a.id_animal = p.id_animal
INNER JOIN Consulta c ON p.id_prontuario = c.id_prontuario
WHERE a.status_atual = 'Disponível'
ORDER BY a.nome;


