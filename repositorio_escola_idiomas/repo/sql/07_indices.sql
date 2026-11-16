\timing off
\echo '=== ANTES: sem índices de apoio ==='
DROP INDEX IF EXISTS idx_matricula_turma_sit, idx_turma_semestre;
-- (UNIQUE(id_aluno,id_turma) já cobre id_aluno como prefixo; removemos temporariamente para medir)
BEGIN;
ALTER TABLE matricula DROP CONSTRAINT matricula_id_aluno_id_turma_key;
ALTER TABLE avaliacao DROP CONSTRAINT avaliacao_id_matricula_tipo_key;
\echo '--- Q1: matrículas do aluno 12345 ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT * FROM matricula WHERE id_aluno=12345;
\echo '--- Q2: avaliações de uma matrícula ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT * FROM avaliacao WHERE id_matricula=150000;
\echo '--- Q3: turmas do semestre 2026.1 ---'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM turma WHERE semestre='2026.1';
\echo '--- Q4: matrículas ativas por turma ---'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT count(*) FROM matricula WHERE id_turma=11 AND situacao='ATIVA';
ROLLBACK;
\echo '=== DEPOIS: UNIQUE restauradas + índices criados ==='
-- Q1 e Q2 voltam a usar os índices implícitos das UNIQUE restauradas (id_aluno e id_matricula são prefixos)
CREATE INDEX idx_matricula_turma_sit ON matricula(id_turma, situacao);
CREATE INDEX idx_turma_semestre ON turma(semestre);
ANALYZE;
\echo '--- Q1 ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT * FROM matricula WHERE id_aluno=12345;
\echo '--- Q2 (UNIQUE id_matricula,tipo restaurado) ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT * FROM avaliacao WHERE id_matricula=150000;
\echo '--- Q3 ---'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM turma WHERE semestre='2026.1';
\echo '--- Q4 ---'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT count(*) FROM matricula WHERE id_turma=11 AND situacao='ATIVA';
