#!/usr/bin/env bash
# Reproduz o experimento no PostgreSQL. Requer PostgreSQL 14+ e o banco "escola_idiomas" criado.
# Uso: createdb escola_idiomas && ./run_all_postgre.sh   (use PGHOST/PGUSER/PGPASSWORD se precisar)
set -e
DB=${1:-escola_idiomas}; S=sql/postgres; E=evidencias/postgres; mkdir -p $E
for f in 01_schema 02_carga 03_carga_volume; do psql -d $DB -v ON_ERROR_STOP=1 -q -f $S/$f.sql; done
for f in 05_tipos 04_testes_restricoes 06_consultas 07_indices 09_diferencas; do psql -d $DB -f $S/$f.sql > $E/$f.txt 2>&1; done
$S/08_concorrencia.sh > $E/08_concorrencia.txt 2>&1 || true
echo "Evidencias do PostgreSQL em ./$E"
