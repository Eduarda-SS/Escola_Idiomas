\set ON_ERROR_STOP off
\echo '--- T1: CPF com letras (CHECK) ---'
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','1234567890A','x1@m.com','2000-01-01');
\echo '--- T2: CPF duplicado (UNIQUE) ---'
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','00000000001','x2@m.com','2000-01-01');
\echo '--- T3: e-mail inválido (CHECK) ---'
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','99999999991','semarroba','2000-01-01');
\echo '--- T4: nascimento no futuro (CHECK) ---'
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','99999999992','x3@m.com','2999-01-01');
\echo '--- T5: nome nulo (NOT NULL) ---'
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES (NULL,'99999999993','x4@m.com','2000-01-01');
\echo '--- T6: nota 11 (CHECK) ---'
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao) VALUES (1,'ORAL',11,CURRENT_DATE);
\echo '--- T7: avaliação duplicada na matrícula (UNIQUE) ---'
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao) VALUES (1,'PROVA1',5,CURRENT_DATE);
\echo '--- T8: matrícula com aluno inexistente (FK) ---'
INSERT INTO matricula(id_aluno,id_turma) VALUES (999999,1);
\echo '--- T9: matrícula repetida aluno/turma (copia a matrícula 1) (UNIQUE) ---'
INSERT INTO matricula(id_aluno,id_turma) SELECT id_aluno,id_turma FROM matricula WHERE id_matricula=1;
\echo '--- T10: nível inválido (CHECK) ---'
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (2,1,'Z9','2027.1',1,'08:00','10:00',10);
\echo '--- T11: hora fim < início (CHECK) ---'
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (2,1,'A1','2027.1',1,'10:00','08:00',10);
\echo '--- T12: professor sem habilitação no idioma (TRIGGER) ---'
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (4,1,'A1','2027.1',1,'08:00','10:00',10);
\echo '--- T13: professor com choque de horário (UNIQUE) ---'
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) SELECT id_idioma,id_professor,'A1',semestre,dia_semana,hora_inicio,hora_fim,10 FROM turma WHERE id_turma=1;
\echo '--- T14: apagar turma com matrículas (FK RESTRICT) ---'
DELETE FROM turma WHERE id_turma=1;
\echo '--- T15: turma lotada (TRIGGER de vagas) ---'
BEGIN;
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (3,2,'A1','2030.1',7,'08:00','10:00',2);
INSERT INTO matricula(id_aluno,id_turma) SELECT 40000+g, (SELECT max(id_turma) FROM turma) FROM generate_series(1,3) g;
ROLLBACK;
\echo '--- T16: ON DELETE CASCADE (avaliações removidas junto da matrícula) ---'
BEGIN;
SELECT count(*) AS avaliacoes_antes FROM avaliacao WHERE id_matricula=1;
DELETE FROM matricula WHERE id_matricula=1;
SELECT count(*) AS avaliacoes_depois FROM avaliacao WHERE id_matricula=1;
ROLLBACK;
\echo '--- T17: inserção válida (controle positivo) ---'
BEGIN;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('Valido','88888888888','valido@m.com','1999-05-05') RETURNING id_aluno;
ROLLBACK;
