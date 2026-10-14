
USE petcare_db;

CREATE OR REPLACE VIEW vw_relatorio_ong AS
SELECT
    o.id_ong,
    o.nome AS ong,
    o.situacao_cadastro,
    (SELECT COUNT(*) FROM Animal a WHERE a.id_ong = o.id_ong) AS total_animais,
    (SELECT COUNT(*) FROM Animal a WHERE a.id_ong = o.id_ong AND a.status_atual = 'Disponível') AS disponiveis,
    (SELECT COUNT(*) FROM Animal a WHERE a.id_ong = o.id_ong AND a.status_atual = 'Adotado')    AS adotados,
    (SELECT COUNT(*) FROM pedidoAdocao p JOIN Animal a ON a.id_animal = p.id_animal
      WHERE a.id_ong = o.id_ong AND p.status_pedido = 'Em análise') AS pedidos_em_analise,
    (SELECT COUNT(*) FROM pedidoAdocao p JOIN Animal a ON a.id_animal = p.id_animal
      WHERE a.id_ong = o.id_ong AND p.status_pedido = 'Aprovado')   AS pedidos_aprovados,
    (SELECT COALESCE(SUM(pt.valor), 0) FROM Patrocinio pt WHERE pt.id_ong = o.id_ong) AS total_patrocinio,
    (SELECT COUNT(DISTINCT at.id_veterinario) FROM Atuacao at
      WHERE at.id_ong = o.id_ong AND at.data_fim IS NULL) AS veterinarios_ativos
FROM Ong o;
