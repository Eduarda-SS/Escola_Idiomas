#!/usr/bin/env bash
# Reproduz o experimento no MySQL 8.0+. Requer o banco criado: mysql -u root -p -e "CREATE DATABASE escola_idiomas CHARACTER SET utf8mb4"
# Uso: ./run_all_mysql.sh [usuario]    (pede a senha; ou use MYSQL_PWD)
set -e
U=${1:-root}; DB=escola_idiomas; S=sql/mysql; E=evidencias/mysql; mkdir -p $E
M="mysql -u$U -D $DB"
for f in 01_schema 02_carga 03_carga_volume; do $M < $S/$f.sql; done
$M -t -n < $S/05_tipos.sql > $E/05_tipos.txt 2>&1
$M --force -t -n < $S/04_testes_restricoes.sql > $E/04_testes_restricoes.txt 2>&1
$M --force -t -n < $S/09_diferencas.sql > $E/09_diferencas.txt 2>&1
$M -t -n < $S/06_consultas.sql > $E/06_consultas.txt 2>&1
$M -r -n < $S/07_indices.sql > $E/07_indices.txt 2>&1
MYSQL="mysql -u$U -D $DB" $S/08_concorrencia.sh > $E/08_concorrencia.txt 2>&1 || true
echo "Evidencias do MySQL em ./$E"
