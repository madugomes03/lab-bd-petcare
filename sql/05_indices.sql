USE petcare_db;

-- B4: índices adotados após os estudos de EXPLAIN
CREATE INDEX idx_consulta_data         ON Consulta(data);
CREATE INDEX idx_animal_status_especie ON Animal(status_atual, especie);
