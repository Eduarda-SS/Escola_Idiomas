#!/usr/bin/env bash
# Reproduz todo o experimento. Requer PostgreSQL 14+ e o banco "escola_idiomas" criado.
# Uso: createdb escola_idiomas && ./run_all.sh
set -e
DB=${1:-escola_idiomas}
for f in 01_schema 02_carga 03_carga_volume; do psql -d $DB -v ON_ERROR_STOP=1 -q -f sql/$f.sql; done
mkdir -p evidencias
for f in 05_tipos 04_testes_restricoes 06_consultas 07_indices; do psql -d $DB -f sql/$f.sql > evidencias/$f.txt 2>&1; done
echo "Evidências geradas em ./evidencias"
