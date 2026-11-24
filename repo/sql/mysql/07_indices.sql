-- ATENCAO: os tempos desta saida sao de execucao unica (podem incluir cache frio).
-- Os valores do artigo vem do bench.py (mediana de 7 execucoes, evidencias/comparacao/).
-- Efeito dos indices (MySQL). Rode apos 01, 02 e 03 (banco sem indices explicitos).
-- "Sem indice" = copia das tabelas sem nenhuma chave; "esquema" = PK/UNIQUE/FK do 01_schema; "indices" = indices extras.
DROP TABLE IF EXISTS matricula_sem, avaliacao_sem, turma_sem;
CREATE TABLE matricula_sem AS SELECT * FROM matricula;
CREATE TABLE avaliacao_sem AS SELECT * FROM avaliacao;
CREATE TABLE turma_sem     AS SELECT * FROM turma;
ANALYZE TABLE matricula_sem, avaliacao_sem, turma_sem;

SELECT '=== S0: SEM INDICE (copias sem chaves) ===' AS estagio;
EXPLAIN ANALYZE SELECT * FROM matricula_sem WHERE id_aluno=12345;
EXPLAIN ANALYZE SELECT * FROM avaliacao_sem WHERE id_matricula=150000;
EXPLAIN ANALYZE SELECT * FROM turma_sem WHERE semestre='2026.1';
EXPLAIN ANALYZE SELECT COUNT(*) FROM matricula_sem WHERE id_turma=11 AND situacao='ATIVA';

SELECT '=== S1: INDICES DO ESQUEMA (PK, UNIQUE, indice implicito da FK) ===' AS estagio;
EXPLAIN ANALYZE SELECT * FROM matricula WHERE id_aluno=12345;
EXPLAIN ANALYZE SELECT * FROM avaliacao WHERE id_matricula=150000;
EXPLAIN ANALYZE SELECT * FROM turma WHERE semestre='2026.1';
EXPLAIN ANALYZE SELECT COUNT(*) FROM matricula WHERE id_turma=11 AND situacao='ATIVA';

CREATE INDEX idx_matricula_turma_sit ON matricula(id_turma, situacao);
CREATE INDEX idx_turma_semestre ON turma(semestre);
ANALYZE TABLE matricula, turma;

SELECT '=== S2: COM INDICES EXPLICITOS ===' AS estagio;
EXPLAIN ANALYZE SELECT * FROM matricula WHERE id_aluno=12345;
EXPLAIN ANALYZE SELECT * FROM avaliacao WHERE id_matricula=150000;
EXPLAIN ANALYZE SELECT * FROM turma WHERE semestre='2026.1';
EXPLAIN ANALYZE SELECT COUNT(*) FROM matricula WHERE id_turma=11 AND situacao='ATIVA';

DROP TABLE matricula_sem, avaliacao_sem, turma_sem;
