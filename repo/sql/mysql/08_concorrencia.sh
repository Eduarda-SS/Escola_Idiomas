#!/usr/bin/env bash
# T18 (MySQL): duas matriculas simultaneas na ultima vaga. Esperado: exatamente 1 sucesso.
# Em Workbench: abra DUAS abas de consulta; na aba A rode o bloco A, e em ate 2 s rode o bloco B na aba B (ver README).
MYSQL=${MYSQL:-"mysql -uroot -D escola_idiomas"}
T=$($MYSQL -N -e "INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (3,2,'A1','2031.1',7,'08:00','10:00',1); SELECT LAST_INSERT_ID();")
echo "turma de teste=$T (1 vaga)"
( $MYSQL -e "START TRANSACTION; INSERT INTO matricula(id_aluno,id_turma) VALUES (40001,$T); DO SLEEP(2); COMMIT;" 2>&1 | sed 's/^/sessao A: /'; echo "sessao A: concluida (COMMIT)" ) &
sleep 0.5
( $MYSQL -e "INSERT INTO matricula(id_aluno,id_turma) VALUES (40002,$T);" 2>&1 | sed 's/^/sessao B: /'; echo "sessao B: concluida" ) &
wait
$MYSQL -t -e "SELECT COUNT(*) AS matriculas_ativas, (SELECT vagas FROM turma WHERE id_turma=$T) AS vagas FROM matricula WHERE id_turma=$T"
$MYSQL -e "DELETE FROM matricula WHERE id_turma=$T; DELETE FROM turma WHERE id_turma=$T"
