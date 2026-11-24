#!/usr/bin/env bash
# ============================================================
# 08_concorrencia.sh | PostgreSQL 16 | T18
# Duas sessoes matriculam ao mesmo tempo na ULTIMA vaga de uma turma de 1 vaga.
# Esperado com o gatilho correto (FOR UPDATE): exatamente 1 matricula. Uso: ./sql/postgres/08_concorrencia.sh
# Saida: evidencias/postgres/08_concorrencia.txt
# ============================================================
PSQL="psql -d escola_idiomas -v ON_ERROR_STOP=1 -q"
$PSQL -c "INSERT INTO turma(id_idioma,id_professor,nivel,semestre,dia_semana,hora_inicio,hora_fim,vagas) VALUES (3,2,'A1','2031.1',7,'08:00','10:00',1)"
T=$($PSQL -At -c "SELECT max(id_turma) FROM turma")
echo "turma de teste=$T (1 vaga)"
( $PSQL -c "BEGIN; INSERT INTO matricula(id_aluno,id_turma) VALUES (40001,$T); SELECT pg_sleep(2); COMMIT;" 2>&1 | sed 's/^/sessao A: /' ) &
sleep 0.5
( $PSQL -c "INSERT INTO matricula(id_aluno,id_turma) VALUES (40002,$T);" 2>&1 | sed 's/^/sessao B: /' ) &
wait
$PSQL -c "SELECT count(*) AS matriculas_ativas, (SELECT vagas FROM turma WHERE id_turma=$T) AS vagas FROM matricula WHERE id_turma=$T"
$PSQL -c "DELETE FROM matricula WHERE id_turma=$T; DELETE FROM turma WHERE id_turma=$T"
