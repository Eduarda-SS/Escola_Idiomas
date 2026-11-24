SELECT table_name AS tabela, column_name AS coluna, column_type AS tipo, is_nullable AS nulo
FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name IN ('aluno','turma','avaliacao')
ORDER BY table_name, ordinal_position;
SELECT tc.table_name AS tabela, tc.constraint_name AS restricao, tc.constraint_type AS tipo
FROM information_schema.table_constraints tc WHERE tc.table_schema = DATABASE() ORDER BY 1,3,2;
SELECT tc.constraint_type AS tipo, COUNT(*) AS qtde
FROM information_schema.table_constraints tc WHERE tc.table_schema = DATABASE() GROUP BY 1 ORDER BY 1;
SELECT COUNT(*) AS gatilhos FROM information_schema.triggers WHERE trigger_schema = DATABASE();
