-- Tabela auxiliar de numeros (MySQL nao tem generate_series)
DROP TABLE IF EXISTS seq;
CREATE TABLE seq (n INT PRIMARY KEY);
SET SESSION cte_max_recursion_depth = 400000;
INSERT INTO seq WITH RECURSIVE r AS (SELECT 1 AS n UNION ALL SELECT n+1 FROM r WHERE n < 300000) SELECT n FROM r;

INSERT INTO idioma(nome) VALUES ('Inglês'),('Espanhol'),('Francês'),('Alemão'),('Italiano');
INSERT INTO professor(nome,email,salario_hora)
SELECT CONCAT('Professor ',n), CONCAT('prof',n,'@escola.com'), 40 + (n%5)*5 FROM seq WHERE n <= 20 ORDER BY n;
INSERT INTO professor_idioma SELECT n, (n%5)+1 FROM seq WHERE n <= 20;
INSERT INTO professor_idioma SELECT n, ((n+1)%5)+1 FROM seq WHERE n <= 20 AND (n-1)%3 = 0;

-- turmas 2025.2 e 2026.1 (160 turmas, ids 1..160)
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas)
SELECT (p.n%5)+1, p.n, ELT(1+((p.n+d.n)%6),'A1','A2','B1','B2','C1','C2'),
       s.sem, d.n, MAKETIME(8+h.n*2,0,0), MAKETIME(10+h.n*2,0,0), 20
FROM (SELECT n FROM seq WHERE n<=20) p
JOIN (SELECT '2025.2' sem UNION ALL SELECT '2026.1') s
JOIN (SELECT n FROM seq WHERE n<=2) d
JOIN (SELECT n-1 AS n FROM seq WHERE n<=2) h
ORDER BY p.n, s.sem, d.n, h.n;

INSERT INTO aluno(nome,cpf,email,data_nascimento,telefone)
SELECT CONCAT('Aluno ',n), LPAD(n,11,'0'), CONCAT('aluno',n,'@mail.com'),
       DATE_ADD('1980-01-01', INTERVAL (n*37 % 9000) DAY), CONCAT('79', LPAD(90000000+n,9,'0'))
FROM seq WHERE n <= 50000 ORDER BY n;

-- matriculas: 8 a 20 alunos por turma (2025.2 concluidas, 2026.1 ativas)
-- OBS MySQL: o gatilho de vagas faz SELECT ... FOR UPDATE em turma; o MySQL (erro 1442) nao permite isso
-- quando o INSERT ... SELECT da carga le a propria turma. Por isso a lista de turmas e materializada antes.
DROP TEMPORARY TABLE IF EXISTS tmp_turma;
CREATE TEMPORARY TABLE tmp_turma AS SELECT id_turma, semestre FROM turma WHERE id_turma <= 160;
INSERT IGNORE INTO matricula(id_aluno,id_turma,situacao,data_matricula)
SELECT 1+((t.id_turma*97 + k.n*13) % 50000), t.id_turma,
       CASE WHEN t.semestre='2025.2' THEN 'CONCLUIDA'
            WHEN k.n%10=0 THEN 'TRANCADA' WHEN k.n%15=0 THEN 'CANCELADA' ELSE 'ATIVA' END,
       DATE_ADD(CASE WHEN t.semestre='2025.2' THEN DATE '2025-08-01' ELSE DATE '2026-02-01' END, INTERVAL (k.n%10) DAY)
FROM tmp_turma t JOIN (SELECT n FROM seq WHERE n<=20) k ON k.n <= 8 + (t.id_turma%13)
ORDER BY t.id_turma, k.n;

-- notas ~ media 7 (soma de uniformes); semestre corrente so tem PROVA1 e ORAL
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao)
SELECT m.id_matricula, tp.tipo,
       ROUND(LEAST(10,GREATEST(0, 7 + (RAND()+RAND()+RAND()-1.5)*3.2)),2),
       DATE_ADD(m.data_matricula, INTERVAL 45 DAY)
FROM matricula m JOIN turma t USING(id_turma)
JOIN (SELECT 'PROVA1' tipo UNION ALL SELECT 'PROVA2' UNION ALL SELECT 'ORAL' UNION ALL SELECT 'TRABALHO') tp
WHERE m.situacao IN ('ATIVA','CONCLUIDA')
  AND (t.semestre='2025.2' OR tp.tipo IN ('PROVA1','ORAL'));
