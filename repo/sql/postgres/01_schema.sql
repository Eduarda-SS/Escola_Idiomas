-- ============================================================
-- 01_schema.sql | PostgreSQL 16 | Escola de Idiomas
-- Cria as 7 tabelas com tipos, PK, FK, UNIQUE e CHECK, e 2 gatilhos
-- (vagas da turma; professor habilitado no idioma).
-- Executar: psql -d escola_idiomas -f sql/postgres/01_schema.sql
-- Apaga e recria as tabelas (CASCADE). Rode antes de 02 e 03.
-- ============================================================
DROP TABLE IF EXISTS avaliacao, matricula, turma, professor_idioma, professor, idioma, aluno CASCADE;

CREATE TABLE aluno (
  id_aluno        SERIAL PRIMARY KEY,
  nome            VARCHAR(100) NOT NULL,
  cpf             CHAR(11)     NOT NULL UNIQUE CHECK (cpf ~ '^[0-9]{11}$'),
  email           VARCHAR(120) NOT NULL UNIQUE CHECK (email LIKE '%_@_%._%'),
  data_nascimento DATE         NOT NULL CHECK (data_nascimento <= CURRENT_DATE),
  telefone        VARCHAR(15),
  criado_em       TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE idioma (
  id_idioma SMALLSERIAL PRIMARY KEY,
  nome      VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE professor (
  id_professor SERIAL PRIMARY KEY,
  nome         VARCHAR(100) NOT NULL,
  email        VARCHAR(120) NOT NULL UNIQUE,
  salario_hora NUMERIC(8,2) NOT NULL CHECK (salario_hora > 0)
);

CREATE TABLE professor_idioma (
  id_professor INT      NOT NULL REFERENCES professor ON DELETE CASCADE,
  id_idioma    SMALLINT NOT NULL REFERENCES idioma    ON DELETE RESTRICT,
  PRIMARY KEY (id_professor, id_idioma)
);

CREATE TABLE turma (
  id_turma     SERIAL PRIMARY KEY,
  id_idioma    SMALLINT NOT NULL REFERENCES idioma    ON DELETE RESTRICT,
  id_professor INT      NOT NULL REFERENCES professor ON DELETE RESTRICT,
  nivel        VARCHAR(2) NOT NULL CHECK (nivel IN ('A1','A2','B1','B2','C1','C2')),
  semestre     CHAR(6)  NOT NULL CHECK (semestre ~ '^[0-9]{4}\.[12]$'),
  dia_semana   SMALLINT NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
  hora_inicio  TIME     NOT NULL,
  hora_fim     TIME     NOT NULL,
  vagas        SMALLINT NOT NULL CHECK (vagas BETWEEN 1 AND 30),
  CHECK (hora_fim > hora_inicio),
  UNIQUE (id_professor, semestre, dia_semana, hora_inicio)
);

CREATE TABLE matricula (
  id_matricula SERIAL PRIMARY KEY,
  id_aluno     INT NOT NULL REFERENCES aluno ON DELETE RESTRICT,
  id_turma     INT NOT NULL REFERENCES turma ON DELETE RESTRICT,
  data_matricula DATE NOT NULL DEFAULT CURRENT_DATE,
  situacao     VARCHAR(10) NOT NULL DEFAULT 'ATIVA'
               CHECK (situacao IN ('ATIVA','TRANCADA','CANCELADA','CONCLUIDA')),
  UNIQUE (id_aluno, id_turma)
);

CREATE TABLE avaliacao (
  id_avaliacao SERIAL PRIMARY KEY,
  id_matricula INT NOT NULL REFERENCES matricula ON DELETE CASCADE,
  tipo         VARCHAR(10) NOT NULL CHECK (tipo IN ('PROVA1','PROVA2','ORAL','TRABALHO')),
  nota         NUMERIC(4,2) NOT NULL CHECK (nota BETWEEN 0 AND 10),
  data_aplicacao DATE NOT NULL,
  UNIQUE (id_matricula, tipo)
);

-- Regra de negócio: não exceder vagas da turma
CREATE OR REPLACE FUNCTION fn_checa_vagas() RETURNS trigger AS $$
BEGIN
  -- trava a linha da turma: serializa matrículas concorrentes e evita estourar as vagas
  PERFORM 1 FROM turma WHERE id_turma = NEW.id_turma FOR UPDATE;
  IF NEW.situacao = 'ATIVA' AND
     (SELECT count(*) FROM matricula WHERE id_turma = NEW.id_turma AND situacao='ATIVA')
     >= (SELECT vagas FROM turma WHERE id_turma = NEW.id_turma) THEN
    RAISE EXCEPTION 'Turma % sem vagas', NEW.id_turma;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_vagas BEFORE INSERT ON matricula
  FOR EACH ROW EXECUTE FUNCTION fn_checa_vagas();

-- Regra de negócio: professor só leciona idioma que domina
CREATE OR REPLACE FUNCTION fn_prof_idioma() RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM professor_idioma
                 WHERE id_professor=NEW.id_professor AND id_idioma=NEW.id_idioma) THEN
    RAISE EXCEPTION 'Professor % nao habilitado no idioma %', NEW.id_professor, NEW.id_idioma;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_prof_idioma BEFORE INSERT OR UPDATE ON turma
  FOR EACH ROW EXECUTE FUNCTION fn_prof_idioma();
