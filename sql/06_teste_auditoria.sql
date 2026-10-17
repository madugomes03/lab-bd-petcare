USE petcare_db;

START TRANSACTION;
SET @usuario_app = 'sofia.admong';

UPDATE pedidoAdocao
   SET status_pedido = 'Recusado',
       parecer = 'Moradia inadequada para o porte do animal',
       id_adm_ong = 3,
       data_decisao = NOW()
 WHERE id_pedido = 1;

UPDATE animal SET status_atual = 'Disponível' WHERE id_animal = 1;
COMMIT;

SET @usuario_app = NULL;

SELECT tabela, id_registro, campo, valor_anterior, valor_posterior, autor, data_hora
  FROM auditoria
 ORDER BY id_auditoria DESC;
 