-- Escola de Idiomas - Esquema (MySQL 8.0 / MySQL Workbench)
-- No Workbench: File > Open SQL Script, selecione o banco (USE) e execute com o raio (Ctrl+Shift+Enter).
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS avaliacao, matricula, turma, professor_idioma, professor, idioma, aluno;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE aluno (
  id_aluno        INT AUTO_INCREMENT PRIMARY KEY,
  nome            VARCHAR(100) NOT NULL,
  cpf             CHAR(11)     NOT NULL,
  email           VARCHAR(120) NOT NULL,
  data_nascimento DATE         NOT NULL,
  telefone        VARCHAR(15),
  criado_em       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_aluno_cpf   UNIQUE (cpf),
  CONSTRAINT uq_aluno_email UNIQUE (email),
  CONSTRAINT chk_aluno_cpf   CHECK (cpf REGEXP '^[0-9]{11}$'),
  CONSTRAINT chk_aluno_email CHECK (email LIKE '%_@_%._%')
  -- data_nascimento <= CURRENT_DATE NAO pode ser CHECK no MySQL (funcao nao deterministica): ver gatilho abaixo
) ENGINE=InnoDB;

CREATE TABLE idioma (
  id_idioma SMALLINT AUTO_INCREMENT PRIMARY KEY,
  nome      VARCHAR(40) NOT NULL,
  CONSTRAINT uq_idioma_nome UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE professor (
  id_professor INT AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(100) NOT NULL,
  email        VARCHAR(120) NOT NULL,
  salario_hora DECIMAL(8,2) NOT NULL,
  CONSTRAINT uq_prof_email UNIQUE (email),
  CONSTRAINT chk_prof_salario CHECK (salario_hora > 0)
) ENGINE=InnoDB;

CREATE TABLE professor_idioma (
  id_professor INT      NOT NULL,
  id_idioma    SMALLINT NOT NULL,
  PRIMARY KEY (id_professor, id_idioma),
  CONSTRAINT fk_pi_prof   FOREIGN KEY (id_professor) REFERENCES professor(id_professor) ON DELETE CASCADE,
  CONSTRAINT fk_pi_idioma FOREIGN KEY (id_idioma)    REFERENCES idioma(id_idioma)       ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE turma (
  id_turma     INT AUTO_INCREMENT PRIMARY KEY,
  id_idioma    SMALLINT NOT NULL,
  id_professor INT      NOT NULL,
  nivel        VARCHAR(2) NOT NULL,
  semestre     CHAR(6)  NOT NULL,
  dia_semana   SMALLINT NOT NULL,
  hora_inicio  TIME     NOT NULL,
  hora_fim     TIME     NOT NULL,
  vagas        SMALLINT NOT NULL,
  CONSTRAINT fk_turma_idioma FOREIGN KEY (id_idioma)    REFERENCES idioma(id_idioma)       ON DELETE RESTRICT,
  CONSTRAINT fk_turma_prof   FOREIGN KEY (id_professor) REFERENCES professor(id_professor) ON DELETE RESTRICT,
  CONSTRAINT chk_turma_nivel    CHECK (nivel IN ('A1','A2','B1','B2','C1','C2')),
  CONSTRAINT chk_turma_semestre CHECK (semestre REGEXP '^[0-9]{4}\\.[12]$'),
  CONSTRAINT chk_turma_dia      CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT chk_turma_vagas    CHECK (vagas BETWEEN 1 AND 30),
  CONSTRAINT chk_turma_hora     CHECK (hora_fim > hora_inicio),
  CONSTRAINT uq_turma_horario   UNIQUE (id_professor, semestre, dia_semana, hora_inicio)
) ENGINE=InnoDB;

CREATE TABLE matricula (
  id_matricula   INT AUTO_INCREMENT PRIMARY KEY,
  id_aluno       INT NOT NULL,
  id_turma       INT NOT NULL,
  data_matricula DATE NOT NULL DEFAULT (CURRENT_DATE),
  situacao       VARCHAR(10) NOT NULL DEFAULT 'ATIVA',
  CONSTRAINT fk_mat_aluno FOREIGN KEY (id_aluno) REFERENCES aluno(id_aluno) ON DELETE RESTRICT,
  CONSTRAINT fk_mat_turma FOREIGN KEY (id_turma) REFERENCES turma(id_turma) ON DELETE RESTRICT,
  CONSTRAINT chk_mat_situacao CHECK (situacao IN ('ATIVA','TRANCADA','CANCELADA','CONCLUIDA')),
  CONSTRAINT uq_mat_aluno_turma UNIQUE (id_aluno, id_turma)
) ENGINE=InnoDB;

CREATE TABLE avaliacao (
  id_avaliacao   INT AUTO_INCREMENT PRIMARY KEY,
  id_matricula   INT NOT NULL,
  tipo           VARCHAR(10) NOT NULL,
  nota           DECIMAL(4,2) NOT NULL,
  data_aplicacao DATE NOT NULL,
  CONSTRAINT fk_av_mat FOREIGN KEY (id_matricula) REFERENCES matricula(id_matricula) ON DELETE CASCADE,
  CONSTRAINT chk_av_tipo CHECK (tipo IN ('PROVA1','PROVA2','ORAL','TRABALHO')),
  CONSTRAINT chk_av_nota CHECK (nota BETWEEN 0 AND 10),
  CONSTRAINT uq_av_mat_tipo UNIQUE (id_matricula, tipo)
) ENGINE=InnoDB;

DELIMITER $$

-- Substitui o CHECK (data_nascimento <= CURRENT_DATE), que o MySQL recusa
CREATE TRIGGER trg_aluno_nasc_ins BEFORE INSERT ON aluno FOR EACH ROW
BEGIN
  IF NEW.data_nascimento > CURRENT_DATE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de nascimento no futuro';
  END IF;
END$$

CREATE TRIGGER trg_aluno_nasc_upd BEFORE UPDATE ON aluno FOR EACH ROW
BEGIN
  IF NEW.data_nascimento > CURRENT_DATE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data de nascimento no futuro';
  END IF;
END$$

-- Regra de negocio: nao exceder vagas (trava a linha da turma para serializar matriculas concorrentes)
CREATE TRIGGER trg_vagas BEFORE INSERT ON matricula FOR EACH ROW
BEGIN
  DECLARE v_vagas INT;
  DECLARE v_ativos INT;
  SELECT vagas INTO v_vagas FROM turma WHERE id_turma = NEW.id_turma FOR UPDATE;
  IF NEW.situacao = 'ATIVA' THEN
    SELECT COUNT(*) INTO v_ativos FROM matricula WHERE id_turma = NEW.id_turma AND situacao = 'ATIVA';
    IF v_ativos >= v_vagas THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Turma sem vagas';
    END IF;
  END IF;
END$$

-- Regra de negocio: professor so leciona idioma que domina
CREATE TRIGGER trg_prof_idioma_ins BEFORE INSERT ON turma FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM professor_idioma WHERE id_professor = NEW.id_professor AND id_idioma = NEW.id_idioma) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Professor nao habilitado no idioma';
  END IF;
END$$

CREATE TRIGGER trg_prof_idioma_upd BEFORE UPDATE ON turma FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM professor_idioma WHERE id_professor = NEW.id_professor AND id_idioma = NEW.id_idioma) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Professor nao habilitado no idioma';
  END IF;
END$$

DELIMITER ;
