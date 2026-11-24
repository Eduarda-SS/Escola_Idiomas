-- ============================================================
-- 03_carga_volume.sql | PostgreSQL 16
-- Volume para testes de indice: 11 semestres historicos (4.400 turmas),
-- 300.000 matriculas concluidas e 3 avaliacoes por matricula historica.
-- Executar apos 02_carga.sql (leva cerca de 20 s). Termina com ANALYZE.
-- ============================================================
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas)
SELECT (p%5)+1, p, (ARRAY['A1','A2','B1','B2','C1','C2'])[1+((p+d+h)%6)],
       s, d, make_time(8+h*2,0,0), make_time(10+h*2,0,0), 30
FROM generate_series(1,20) p,
     unnest(ARRAY['2020.1','2020.2','2021.1','2021.2','2022.1','2022.2','2023.1','2023.2','2024.1','2024.2','2025.1']) s,
     generate_series(1,5) d, generate_series(0,3) h;
INSERT INTO matricula(id_aluno,id_turma,situacao,data_matricula)
SELECT a, t, 'CONCLUIDA', DATE '2020-01-01' + (a % 2000)
FROM (SELECT 1+(g%50000) AS a, 161+((g*7)%4400) AS t, g FROM generate_series(1,300000) g) x
ON CONFLICT (id_aluno,id_turma) DO NOTHING;
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao)
SELECT m.id_matricula, tp, round(least(10,greatest(0, 7 + (random()+random()+random()-1.5)*3.2))::numeric,2), m.data_matricula + 60
FROM matricula m, unnest(ARRAY['PROVA1','PROVA2','ORAL']) tp
WHERE m.id_turma > 160;
ANALYZE;
