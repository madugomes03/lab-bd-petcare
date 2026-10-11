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
WHERE data BETWEEN '2026-01-01 00:00:00' AND '2026-06-30 23:59:59'
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
-- Quais veterinários mantêm vínculo vigente (RN27) com duas ou mais ONGs
-- ao mesmo tempo, e quanto cada um já atendeu?

SELECT
    p.id_pessoa,
    p.nome AS veterinario,
    v.especialidade,
    (SELECT COUNT(*)
     FROM Atuacao a
     WHERE a.id_veterinario = v.id_pessoa
       AND a.data_fim IS NULL) AS ongs_vigentes,
    (SELECT COUNT(*)
     FROM Consulta c
     WHERE c.id_veterinario = v.id_pessoa) AS total_consultas
FROM Veterinario v
INNER JOIN Pessoa p ON v.id_pessoa = p.id_pessoa
WHERE EXISTS (
    SELECT 1
    FROM Atuacao a1
    INNER JOIN Atuacao a2
        ON a2.id_veterinario = a1.id_veterinario
       AND a2.id_ong <> a1.id_ong
    WHERE a1.id_veterinario = v.id_pessoa
      AND a1.data_fim IS NULL
      AND a2.data_fim IS NULL
)
ORDER BY total_consultas DESC;

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
-- CONSULTA 13 - AVANÇADA (NOT EXISTS + SUBCONSULTA)
-- Pergunta de negócio:
-- Quais animais disponíveis estão sem nenhum pedido de adoção em análise,
-- há quantos dias aguardam adoção e quantos pedidos anteriores já tiveram?

SELECT
    a.id_animal,
    a.nome AS animal,
    a.especie,
    o.nome AS ong,
    DATEDIFF(CURDATE(), s.data_inicio) AS dias_disponivel,
    (SELECT COUNT(*)
     FROM pedidoAdocao p
     WHERE p.id_animal = a.id_animal) AS pedidos_anteriores
FROM Animal a
INNER JOIN Ong o ON a.id_ong = o.id_ong
INNER JOIN SituacaoAnimal s
    ON s.id_animal = a.id_animal
   AND s.status = 'Disponível'
   AND s.data_fim IS NULL
WHERE a.status_atual = 'Disponível'
  AND NOT EXISTS (
      SELECT 1
      FROM pedidoAdocao p
      WHERE p.id_animal = a.id_animal
        AND p.status_pedido = 'Em análise'
  )
ORDER BY dias_disponivel DESC;

-- ============================================================
-- CONSULTA 14 - AVANÇADA (AGREGAÇÃO COM COMPARAÇÃO ENTRE TABELAS)
-- Pergunta de negócio:
-- Quais animais disponíveis ou em adoção estão com o esquema vacinal
-- incompleto (doses aplicadas menores que o total de doses da vacina)
-- e quantas doses ainda faltam?

SELECT
    a.id_animal,
    a.nome AS animal,
    a.status_atual,
    v.nome AS vacina,
    COUNT(av.id_aplicacao) AS doses_aplicadas,
    CAST(v.num_dose AS UNSIGNED) AS doses_previstas,
    CAST(v.num_dose AS UNSIGNED) - COUNT(av.id_aplicacao) AS doses_faltantes,
    MAX(av.data_aplicacao) AS ultima_aplicacao
FROM Animal a
INNER JOIN Prontuario pr ON pr.id_animal = a.id_animal
INNER JOIN aplicacaoVacina av ON av.id_prontuario = pr.id_prontuario
INNER JOIN Vacina v ON v.id_vacina = av.id_vacina
WHERE a.status_atual IN ('Disponível', 'Em Adoção')
GROUP BY a.id_animal, a.nome, a.status_atual, v.id_vacina, v.nome, v.num_dose
HAVING COUNT(av.id_aplicacao) < CAST(v.num_dose AS UNSIGNED)
ORDER BY doses_faltantes DESC, a.nome;

-- ============================================================
-- CONSULTA 15 - AVANÇADA (AGREGAÇÃO CONDICIONAL + LEFT JOIN)
-- Pergunta de negócio:
-- Como está o fluxo de adoção de cada ONG: quantos pedidos recebeu em
-- cada situação, qual a taxa de aprovação entre os pedidos já decididos
-- e quantos dias, em média, leva até a decisão?

SELECT
    o.nome AS ong,
    COUNT(p.id_pedido) AS total_pedidos,
    COUNT(CASE WHEN p.status_pedido = 'Aprovado'   THEN 1 END) AS aprovados,
    COUNT(CASE WHEN p.status_pedido = 'Recusado'   THEN 1 END) AS recusados,
    COUNT(CASE WHEN p.status_pedido = 'Cancelado'  THEN 1 END) AS cancelados,
    COUNT(CASE WHEN p.status_pedido = 'Em análise' THEN 1 END) AS em_analise,
    ROUND(
        100 * COUNT(CASE WHEN p.status_pedido = 'Aprovado' THEN 1 END)
        / NULLIF(COUNT(CASE WHEN p.status_pedido IN ('Aprovado', 'Recusado') THEN 1 END), 0),
        2
    ) AS taxa_aprovacao_pct,
    ROUND(
        AVG(CASE WHEN p.status_pedido IN ('Aprovado', 'Recusado')
                 THEN DATEDIFF(p.data_decisao, p.data_pedido) END),
        1
    ) AS dias_medios_ate_decisao
FROM Ong o
LEFT JOIN Animal a ON a.id_ong = o.id_ong
LEFT JOIN pedidoAdocao p ON p.id_animal = a.id_animal
GROUP BY o.id_ong, o.nome
ORDER BY taxa_aprovacao_pct DESC;
