-- ============================================================
-- 07_indices.sql | PostgreSQL 16
-- Efeito dos indices em 3 estagios (mesmo metodo do MySQL):
--   S0 sem indice  = copias das tabelas sem chaves
--   S1 esquema     = tabelas reais com PK/UNIQUE/FK (PostgreSQL NAO indexa FK)
--   S2 indices     = + idx_matricula_turma_sit e idx_turma_semestre
-- Rode apos 01, 02 e 03. Saida: evidencias/postgres/07_indices.txt
-- ATENCAO: os tempos desta saida sao de execucao unica (podem incluir cache frio).
-- Os valores do artigo vem do bench.py (mediana de 7 execucoes, evidencias/comparacao/).
-- ============================================================
-- (UNIQUE(id_aluno,id_turma) já cobre id_aluno como prefixo; removemos temporariamente para medir)
-- Q1 e Q2 voltam a usar os índices implícitos das UNIQUE restauradas (id_aluno e id_matricula são prefixos)
\timing off
DROP INDEX IF EXISTS idx_matricula_turma_sit, idx_turma_semestre;
DROP TABLE IF EXISTS matricula_sem, avaliacao_sem, turma_sem;
CREATE TABLE matricula_sem AS SELECT * FROM matricula;
CREATE TABLE avaliacao_sem AS SELECT * FROM avaliacao;
CREATE TABLE turma_sem     AS SELECT * FROM turma;
ANALYZE matricula_sem; ANALYZE avaliacao_sem; ANALYZE turma_sem; ANALYZE matricula; ANALYZE avaliacao; ANALYZE turma;

\echo '=== S0: SEM INDICE (copias sem chaves) ==='
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM matricula_sem WHERE id_aluno=12345;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM avaliacao_sem WHERE id_matricula=150000;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM turma_sem WHERE semestre='2026.1';
EXPLAIN (ANALYZE, COSTS OFF) SELECT COUNT(*) FROM matricula_sem WHERE id_turma=11 AND situacao='ATIVA';

\echo '=== S1: INDICES DO ESQUEMA (PK, UNIQUE; FK sem indice automatico) ==='
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM matricula WHERE id_aluno=12345;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM avaliacao WHERE id_matricula=150000;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM turma WHERE semestre='2026.1';
EXPLAIN (ANALYZE, COSTS OFF) SELECT COUNT(*) FROM matricula WHERE id_turma=11 AND situacao='ATIVA';

CREATE INDEX idx_matricula_turma_sit ON matricula(id_turma, situacao);
CREATE INDEX idx_turma_semestre ON turma(semestre);
ANALYZE matricula; ANALYZE turma;

\echo '=== S2: COM INDICES EXPLICITOS ==='
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM matricula WHERE id_aluno=12345;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM avaliacao WHERE id_matricula=150000;
EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM turma WHERE semestre='2026.1';
EXPLAIN (ANALYZE, COSTS OFF) SELECT COUNT(*) FROM matricula WHERE id_turma=11 AND situacao='ATIVA';

DROP TABLE matricula_sem, avaliacao_sem, turma_sem;
