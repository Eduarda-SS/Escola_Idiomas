SELECT 'C1: Boletim do aluno 100' AS consulta;
SELECT a.nome, i.nome AS idioma, t.nivel, t.semestre,
       ROUND(AVG(av.nota),2) AS media,
       CASE WHEN AVG(av.nota)>=7 THEN 'APROVADO' ELSE 'REPROVADO' END AS resultado
FROM aluno a JOIN matricula m USING(id_aluno) JOIN turma t USING(id_turma)
JOIN idioma i USING(id_idioma) JOIN avaliacao av USING(id_matricula)
WHERE a.id_aluno=100 GROUP BY a.nome,i.nome,t.nivel,t.semestre,m.id_matricula ORDER BY t.semestre;
SELECT 'C2: Ocupacao das turmas de 2026.1 (top 5)' AS consulta;
SELECT t.id_turma, i.nome AS idioma, t.nivel, p.nome AS professor, t.vagas,
       SUM(m.situacao='ATIVA') AS ativos,
       ROUND(100.0*SUM(m.situacao='ATIVA')/t.vagas,1) AS ocupacao_pct
FROM turma t JOIN idioma i USING(id_idioma) JOIN professor p USING(id_professor)
LEFT JOIN matricula m USING(id_turma) WHERE t.semestre='2026.1'
GROUP BY t.id_turma,i.nome,p.nome ORDER BY ocupacao_pct DESC, t.id_turma LIMIT 5;
SELECT 'C3: Media e aprovacao por idioma' AS consulta;
WITH med AS (SELECT m.id_matricula, t.id_idioma, AVG(av.nota) AS media
             FROM matricula m JOIN turma t USING(id_turma) JOIN avaliacao av USING(id_matricula)
             WHERE m.situacao='CONCLUIDA' GROUP BY m.id_matricula,t.id_idioma)
SELECT i.nome AS idioma, COUNT(*) AS matriculas, ROUND(AVG(media),2) AS media_geral,
       ROUND(100.0*SUM(media>=7)/COUNT(*),1) AS aprovacao_pct
FROM med JOIN idioma i USING(id_idioma) GROUP BY i.nome ORDER BY media_geral DESC, i.nome;
SELECT 'C4: Alerta pedagogico 2026.1 (media < 5)' AS consulta;
SELECT a.nome, t.id_turma, ROUND(AVG(av.nota),2) AS media
FROM matricula m JOIN aluno a USING(id_aluno) JOIN turma t USING(id_turma) JOIN avaliacao av USING(id_matricula)
WHERE t.semestre='2026.1' GROUP BY a.nome,t.id_turma,m.id_matricula HAVING AVG(av.nota)<5 ORDER BY media LIMIT 5;
SELECT 'C5: Carga horaria e custo semanal por professor' AS consulta;
SELECT p.nome, COUNT(*) AS turmas_2026_1,
       SUM(TIME_TO_SEC(TIMEDIFF(t.hora_fim,t.hora_inicio))/3600) AS horas_semana,
       SUM(TIME_TO_SEC(TIMEDIFF(t.hora_fim,t.hora_inicio))/3600)*p.salario_hora AS custo_semanal
FROM professor p JOIN turma t USING(id_professor) WHERE t.semestre='2026.1'
GROUP BY p.id_professor, p.nome, p.salario_hora ORDER BY custo_semanal DESC, p.id_professor LIMIT 5;
