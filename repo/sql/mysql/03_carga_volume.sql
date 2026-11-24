-- Historico: 11 semestres anteriores (turmas e matriculas concluidas)
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas)
SELECT (p.n%5)+1, p.n, ELT(1+((p.n+d.n+h.n)%6),'A1','A2','B1','B2','C1','C2'),
       s.sem, d.n, MAKETIME(8+h.n*2,0,0), MAKETIME(10+h.n*2,0,0), 30
FROM (SELECT n FROM seq WHERE n<=20) p
JOIN (SELECT '2020.1' sem UNION ALL SELECT '2020.2' UNION ALL SELECT '2021.1' UNION ALL SELECT '2021.2'
      UNION ALL SELECT '2022.1' UNION ALL SELECT '2022.2' UNION ALL SELECT '2023.1' UNION ALL SELECT '2023.2'
      UNION ALL SELECT '2024.1' UNION ALL SELECT '2024.2' UNION ALL SELECT '2025.1') s
JOIN (SELECT n FROM seq WHERE n<=5) d
JOIN (SELECT n-1 AS n FROM seq WHERE n<=4) h
ORDER BY p.n, s.sem, d.n, h.n;

-- OBS MySQL: AUTO_INCREMENT em INSERT ... SELECT deixa lacunas de id; por isso as turmas historicas
-- sao numeradas por posicao (rn) em vez de assumir ids contiguos como no PostgreSQL.
DROP TEMPORARY TABLE IF EXISTS tmp_hist;
CREATE TEMPORARY TABLE tmp_hist AS
  SELECT id_turma, ROW_NUMBER() OVER (ORDER BY id_turma) AS rn FROM turma WHERE id_turma > 160;
ALTER TABLE tmp_hist ADD PRIMARY KEY (rn);

INSERT IGNORE INTO matricula(id_aluno,id_turma,situacao,data_matricula)
SELECT 1+(s.n%50000), h.id_turma, 'CONCLUIDA', DATE_ADD('2020-01-01', INTERVAL ((1+(s.n%50000)) % 2000) DAY)
FROM seq s JOIN tmp_hist h ON h.rn = 1+((s.n*7)%4400)
WHERE s.n <= 300000 ORDER BY s.n;

INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao)
SELECT m.id_matricula, tp.tipo,
       ROUND(LEAST(10,GREATEST(0, 7 + (RAND()+RAND()+RAND()-1.5)*3.2)),2),
       DATE_ADD(m.data_matricula, INTERVAL 60 DAY)
FROM matricula m
JOIN (SELECT 'PROVA1' tipo UNION ALL SELECT 'PROVA2' UNION ALL SELECT 'ORAL') tp
WHERE m.id_turma > 160;

DROP TABLE seq;
ANALYZE TABLE aluno, idioma, professor, professor_idioma, turma, matricula, avaliacao;
