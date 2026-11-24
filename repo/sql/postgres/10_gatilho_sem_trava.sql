-- ============================================================
-- 10_gatilho_sem_trava.sql | PostgreSQL 16
-- TESTE DE CONTROLE: troca o gatilho de vagas por uma versao SEM
-- SELECT ... FOR UPDATE. Depois rode 08_concorrencia.sh: a turma de 1 vaga
-- termina com 2 matriculas. Restaure o gatilho correto com 01_schema.sql.
-- ============================================================
CREATE OR REPLACE FUNCTION fn_checa_vagas() RETURNS trigger AS $$
BEGIN
  IF NEW.situacao = 'ATIVA' AND
     (SELECT count(*) FROM matricula WHERE id_turma = NEW.id_turma AND situacao='ATIVA')
     >= (SELECT vagas FROM turma WHERE id_turma = NEW.id_turma) THEN
    RAISE EXCEPTION 'Turma % sem vagas', NEW.id_turma;
  END IF;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
