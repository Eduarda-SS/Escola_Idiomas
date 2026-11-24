-- D1: CHECK com funcao nao deterministica (CURRENT_DATE) - aceito pelo PostgreSQL, recusado pelo MySQL
DROP TABLE IF EXISTS teste_check_data;
SELECT 'D1: CHECK (d <= CURRENT_DATE) em MySQL' AS teste;
CREATE TABLE teste_check_data (d DATE, CONSTRAINT chk_d CHECK (d <= CURRENT_DATE));
-- D2: FILTER (WHERE ...) em agregacao - suportado no PostgreSQL, nao existe no MySQL
SELECT 'D2: count(*) FILTER (WHERE ...) em MySQL' AS teste;
SELECT COUNT(*) FILTER (WHERE situacao='ATIVA') FROM matricula;
-- D3: ON CONFLICT DO NOTHING (PostgreSQL) -> MySQL usa INSERT IGNORE / ON DUPLICATE KEY
SELECT 'D3: ON CONFLICT DO NOTHING em MySQL' AS teste;
INSERT INTO idioma(nome) VALUES ('Inglês') ON CONFLICT DO NOTHING;
-- D4: FOR UPDATE em tabela lida pelo proprio INSERT ... SELECT dentro de gatilho (erro 1442 no MySQL)
SELECT 'D4: INSERT ... SELECT FROM turma com gatilho que trava turma (FOR UPDATE)' AS teste;
INSERT INTO matricula(id_aluno,id_turma,situacao)
SELECT 49999, id_turma, 'CANCELADA' FROM turma WHERE id_turma = 2;
