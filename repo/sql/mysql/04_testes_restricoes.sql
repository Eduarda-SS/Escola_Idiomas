-- Testes de restricoes e gatilhos (MySQL). Cada teste tenta violar uma regra.
-- No Workbench: desative "Stop script execution on errors" (botao na barra do editor) ou execute bloco a bloco (Ctrl+Enter).
SELECT 'T1: CPF com letra (CHECK)' AS teste;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','1234567890A','x1@m.com','2000-01-01');
SELECT 'T2: CPF duplicado (UNIQUE)' AS teste;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','00000000001','x2@m.com','2000-01-01');
SELECT 'T3: e-mail invalido (CHECK)' AS teste;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','99999999991','semarroba','2000-01-01');
SELECT 'T4: nascimento no futuro (GATILHO - CHECK com CURRENT_DATE nao e permitido no MySQL)' AS teste;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('X','99999999992','x3@m.com','2999-01-01');
SELECT 'T5: nome nulo (NOT NULL)' AS teste;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES (NULL,'99999999993','x4@m.com','2000-01-01');

SELECT id_matricula INTO @m4 FROM avaliacao GROUP BY id_matricula HAVING COUNT(*)=4 LIMIT 1;
SELECT 'T6: nota 11 (CHECK)' AS teste;
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao) VALUES (@m4,'ORAL',11,CURRENT_DATE);
SELECT 'T7: avaliacao duplicada na matricula (UNIQUE)' AS teste;
INSERT INTO avaliacao(id_matricula,tipo,nota,data_aplicacao) VALUES (@m4,'PROVA1',5,CURRENT_DATE);
SELECT 'T8: matricula com aluno inexistente (FK)' AS teste;
INSERT INTO matricula(id_aluno,id_turma) VALUES (999999,1);
SELECT 'T9: matricula repetida aluno/turma (copia a matricula 1) (UNIQUE)' AS teste;
SELECT id_aluno, id_turma INTO @a1, @t1 FROM matricula WHERE id_matricula=1;
INSERT INTO matricula(id_aluno,id_turma) VALUES (@a1,@t1);
SELECT 'T10: nivel invalido (CHECK)' AS teste;
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (2,1,'Z9','2027.1',1,'08:00','10:00',10);
SELECT 'T11: hora fim anterior ao inicio (CHECK)' AS teste;
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (2,1,'A1','2027.1',1,'10:00','08:00',10);
SELECT 'T12: professor sem habilitacao no idioma (GATILHO)' AS teste;
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (4,1,'A1','2027.1',1,'08:00','10:00',10);
SELECT 'T13: professor com choque de horario (UNIQUE)' AS teste;
SELECT id_idioma,id_professor,semestre,dia_semana,hora_inicio,hora_fim INTO @i,@p,@s,@d,@hi,@hf FROM turma WHERE id_turma=1;
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (@i,@p,'A1',@s,@d,@hi,@hf,10);
SELECT 'T14: apagar turma com matriculas (FK RESTRICT)' AS teste;
DELETE FROM turma WHERE id_turma=1;

SELECT 'T15: turma lotada (GATILHO de vagas) - 3 matriculas em turma de 2 vagas' AS teste;
START TRANSACTION;
INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (3,2,'A1','2030.1',7,'08:00','10:00',2);
SET @tl = LAST_INSERT_ID();
INSERT INTO matricula(id_aluno,id_turma) VALUES (40001,@tl);
INSERT INTO matricula(id_aluno,id_turma) VALUES (40002,@tl);
INSERT INTO matricula(id_aluno,id_turma) VALUES (40003,@tl);
SELECT COUNT(*) AS matriculas_na_turma_lotada FROM matricula WHERE id_turma=@tl;
ROLLBACK;

SELECT 'T16: ON DELETE CASCADE (avaliacoes removidas junto da matricula)' AS teste;
START TRANSACTION;
SELECT COUNT(*) AS avaliacoes_antes FROM avaliacao WHERE id_matricula=@m4;
DELETE FROM matricula WHERE id_matricula=@m4;
SELECT COUNT(*) AS avaliacoes_depois FROM avaliacao WHERE id_matricula=@m4;
ROLLBACK;

SELECT 'T17: insercao valida (controle positivo)' AS teste;
START TRANSACTION;
INSERT INTO aluno(nome,cpf,email,data_nascimento) VALUES ('Valido','88888888888','valido@m.com','1999-05-05');
SELECT ROW_COUNT() AS linhas_inseridas;
ROLLBACK;
