-- ============================================================
-- 02_carga.sql | PostgreSQL 16
-- Carga base: 5 idiomas, 20 professores, 160 turmas (2025.2 e 2026.1),
-- 50.000 alunos, matriculas e notas dos dois ultimos semestres.
-- Executar apos 01_schema.sql. Notas usam random(): valores variam a cada carga.
-- ============================================================
INSERT INTO idioma(nome) VALUES ('Inglês'),('Espanhol'),('Francês'),('Alemão'),('Italiano');
INSERT INTO professor(nome,email,salario_hora)
SELECT 'Professor '||g, 'prof'||g||'@escola.com', 40+ (g%5)*5 FROM generate_series(1,20) g;
-- cada professor habilitado em 1 idioma (g%5+1) e alguns em 2
INSERT INTO professor_idioma SELECT g, (g%5)+1 FROM generate_series(1,20) g;
INSERT INTO professor_idioma SELECT g, ((g+1)%5)+1 FROM generate_series(1,20,3) g;
-- turmas: 2 semestres, para cada professor, 3 horários
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas)
SELECT (p%5)+1, p, (ARRAY['A1','A2','B1','B2','C1','C2'])[1+((p+d)%6)],
       s, d, make_time(8+h*2,0,0), make_time(10+h*2,0,0), 20
FROM generate_series(1,20) p, unnest(ARRAY['2025.2','2026.1']) s,
     generate_series(1,2) d, generate_series(0,1) h;
-- alunos
INSERT INTO aluno(nome,cpf,email,data_nascimento,telefone)
SELECT 'Aluno '||g, lpad(g::text,11,'0'), 'aluno'||g||'@mail.com',
       DATE '1980-01-01' + (g*37 % 9000), '79'||lpad((90000000+g)::text,9,'0')
FROM generate_series(1,50000) g;
-- matrículas dos semestres 2025.2 (concluídas) e 2026.1 (ativas): 8 a 20 alunos por turma
INSERT INTO matricula(id_aluno,id_turma,situacao,data_matricula)
SELECT 1+((t.id_turma*97 + k*13) % 50000), t.id_turma,
       CASE WHEN t.semestre='2025.2' THEN 'CONCLUIDA'
            WHEN k%10=0 THEN 'TRANCADA' WHEN k%15=0 THEN 'CANCELADA' ELSE 'ATIVA' END,
       CASE WHEN t.semestre='2025.2' THEN DATE '2025-08-01' ELSE DATE '2026-02-01' END + (k%10)
FROM turma t, generate_series(1,20) k
WHERE t.id_turma<=160 AND k <= 8 + (t.id_turma%13)
ON CONFLICT (id_aluno,id_turma) DO NOTHING;
-- notas ~ média 7 (soma de uniformes aproxima normal); semestre corrente só tem PROVA1 e ORAL
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao)
SELECT m.id_matricula, tp,
       round(least(10,greatest(0, 7 + (random()+random()+random()-1.5)*3.2))::numeric,2),
       m.data_matricula + 45
FROM matricula m JOIN turma t USING(id_turma),
     unnest(ARRAY['PROVA1','PROVA2','ORAL','TRABALHO']) tp
WHERE m.situacao IN ('ATIVA','CONCLUIDA')
  AND (t.semestre='2025.2' OR tp IN ('PROVA1','ORAL'));
