-- ============================================================
-- 06_consultas.sql | PostgreSQL 16
-- C1 boletim | C2 ocupacao das turmas | C3 aprovacao por idioma |
-- C4 alerta pedagogico | C5 carga horaria e custo por professor.
-- Saida: evidencias/postgres/06_consultas.txt
-- O bench.py le este arquivo: mantenha os marcadores \echo '--- Cn:'.
-- ============================================================
\echo '--- C1: Boletim do aluno 100 (média e situação) ---'
SELECT a.nome, i.nome AS idioma, t.nivel, t.semestre,
       round(avg(av.nota),2) AS media,
       CASE WHEN avg(av.nota)>=7 THEN 'APROVADO' ELSE 'REPROVADO' END AS resultado
FROM aluno a JOIN matricula m USING(id_aluno) JOIN turma t USING(id_turma)
JOIN idioma i USING(id_idioma) JOIN avaliacao av USING(id_matricula)
WHERE a.id_aluno=100 GROUP BY a.nome,i.nome,t.nivel,t.semestre,m.id_matricula ORDER BY t.semestre;
\echo '--- C2: Ocupação das turmas de 2026.1 (top 5 mais cheias) ---'
SELECT t.id_turma, i.nome AS idioma, t.nivel, p.nome AS professor, t.vagas,
       count(m.*) FILTER (WHERE m.situacao='ATIVA') AS ativos,
       round(100.0*count(m.*) FILTER (WHERE m.situacao='ATIVA')/t.vagas,1) AS ocupacao_pct
FROM turma t JOIN idioma i USING(id_idioma) JOIN professor p USING(id_professor)
LEFT JOIN matricula m USING(id_turma) WHERE t.semestre='2026.1'
GROUP BY t.id_turma,i.nome,p.nome ORDER BY ocupacao_pct DESC, t.id_turma LIMIT 5;
\echo '--- C3: Média geral e taxa de aprovação por idioma ---'
WITH med AS (SELECT m.id_matricula, t.id_idioma, avg(av.nota) AS media
             FROM matricula m JOIN turma t USING(id_turma) JOIN avaliacao av USING(id_matricula)
             WHERE m.situacao='CONCLUIDA' GROUP BY m.id_matricula,t.id_idioma)
SELECT i.nome AS idioma, count(*) AS matriculas, round(avg(media),2) AS media_geral,
       round(100.0*count(*) FILTER (WHERE media>=7)/count(*),1) AS aprovacao_pct
FROM med JOIN idioma i USING(id_idioma) GROUP BY i.nome ORDER BY media_geral DESC;
\echo '--- C4: Alunos com média abaixo de 5 em 2026.1 (alerta pedagógico, 5 primeiros) ---'
SELECT a.nome, t.id_turma, round(avg(av.nota),2) AS media
FROM matricula m JOIN aluno a USING(id_aluno) JOIN turma t USING(id_turma) JOIN avaliacao av USING(id_matricula)
WHERE t.semestre='2026.1' GROUP BY a.nome,t.id_turma,m.id_matricula HAVING avg(av.nota)<5 ORDER BY media LIMIT 5;
\echo '--- C5: Carga horária semanal e custo por professor (top 5) ---'
SELECT p.nome, count(*) AS turmas_2026_1,
       sum(EXTRACT(EPOCH FROM (t.hora_fim-t.hora_inicio))/3600) AS horas_semana,
       sum(EXTRACT(EPOCH FROM (t.hora_fim-t.hora_inicio))/3600)*p.salario_hora AS custo_semanal
FROM professor p JOIN turma t USING(id_professor) WHERE t.semestre='2026.1'
GROUP BY p.id_professor ORDER BY custo_semanal DESC LIMIT 5;
