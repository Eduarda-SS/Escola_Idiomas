-- Variante SEM bloqueio, apenas para o teste de controle da concorrencia (restaurar com 01_schema.sql depois)
DROP TRIGGER IF EXISTS trg_vagas;
DELIMITER $$
CREATE TRIGGER trg_vagas BEFORE INSERT ON matricula FOR EACH ROW
BEGIN
  DECLARE v_vagas INT; DECLARE v_ativos INT;
  SELECT vagas INTO v_vagas FROM turma WHERE id_turma = NEW.id_turma;
  IF NEW.situacao = 'ATIVA' THEN
    SELECT COUNT(*) INTO v_ativos FROM matricula WHERE id_turma = NEW.id_turma AND situacao = 'ATIVA';
    IF v_ativos >= v_vagas THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Turma sem vagas'; END IF;
  END IF;
END$$
DELIMITER ;
