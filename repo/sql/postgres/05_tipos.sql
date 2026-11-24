-- ============================================================
-- 05_tipos.sql | PostgreSQL 16
-- Catalogo: colunas/tipos de aluno, turma e avaliacao, e todas as
-- restricoes (PK, FK, UNIQUE, CHECK) do esquema publico.
-- Saida: evidencias/postgres/05_tipos.txt
-- ============================================================
SELECT table_name AS tabela, column_name AS coluna, data_type AS tipo,
       COALESCE(character_maximum_length::text, numeric_precision||','||numeric_scale, '') AS tam, is_nullable AS nulo
FROM information_schema.columns WHERE table_schema='public'
  AND table_name IN ('aluno','turma','avaliacao') ORDER BY table_name, ordinal_position;
SELECT conrelid::regclass AS tabela, conname AS restricao,
  CASE contype WHEN 'p' THEN 'PK' WHEN 'f' THEN 'FK' WHEN 'u' THEN 'UNIQUE' WHEN 'c' THEN 'CHECK' END AS tipo
FROM pg_constraint WHERE connamespace='public'::regnamespace ORDER BY 1,3,2;
