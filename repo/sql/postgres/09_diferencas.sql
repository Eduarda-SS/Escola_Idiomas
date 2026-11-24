-- ============================================================
-- 09_diferencas.sql | PostgreSQL 16
-- Contraparte do mesmo arquivo do MySQL: recursos que o PostgreSQL ACEITA e o
-- MySQL recusa (D1 a D4). Aqui todos devem funcionar. Saida: evidencias/postgres/09_diferencas.txt
-- ============================================================
\echo 'D1: CHECK com CURRENT_DATE (aceito; ja existe em aluno.data_nascimento)'
SELECT conname, pg_get_constraintdef(oid) AS definicao FROM pg_constraint WHERE conname = 'aluno_data_nascimento_check';
\echo 'D2: count(*) FILTER (WHERE ...)'
SELECT count(*) FILTER (WHERE situacao='ATIVA') AS ativas FROM matricula;
\echo 'D3: INSERT ... ON CONFLICT DO NOTHING (nao duplica o idioma)'
INSERT INTO idioma(nome) VALUES ('Inglês') ON CONFLICT DO NOTHING;
SELECT count(*) AS idiomas FROM idioma;
\echo 'D4: INSERT ... SELECT FROM turma com gatilho que trava a turma (FOR UPDATE) - funciona'
BEGIN;
INSERT INTO matricula(id_aluno,id_turma,situacao) SELECT 49999, id_turma, 'CANCELADA' FROM turma WHERE id_turma = 2;
SELECT count(*) AS linhas_inseridas FROM matricula WHERE id_aluno=49999 AND id_turma=2;
ROLLBACK;
\echo 'D5: FK sem indice automatico - indices existentes em matricula'
SELECT indexname FROM pg_indexes WHERE tablename='matricula' ORDER BY 1;
