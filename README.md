# Escola de Idiomas — Projeto de Banco de Dados (Unidade II, Tema 8)

Banco relacional para turmas por idioma, matrículas e notas, implementado em **PostgreSQL 16** e **MySQL 8.0** (Workbench) e comparado por testes executados.

| Pasta/arquivo | Conteúdo |
|---|---|
| `sql/postgres/` | 01 esquema · 02/03 carga · 04 testes de restrições (T1–T17) · 05 tipos · 06 consultas · 07 índices · 08 concorrência (T18) · 09 diferenças de dialeto · 10 controle sem trava |
| `sql/mysql/` | Os mesmos 10 scripts, com a mesma numeração, portados para MySQL (ver `sql/README.md`) |
| `bench.py` | Benchmark comparativo (1 aquecimento + 7 execuções, mediana) — gera `evidencias/comparacao/` |
| `evidencias/` | Saída bruta de cada execução: `postgres/`, `mysql/` e `comparacao/` (mesma numeração dos scripts) |
| `docs/` | Diagrama ER, gráficos, `WORKBENCH.md`, `criar_issues.sh` |

## Reproduzir
```bash
# PostgreSQL
createdb escola_idiomas && ./run_all_postgre.sh
# MySQL
mysql -u root -p -e "CREATE DATABASE escola_idiomas CHARACTER SET utf8mb4" && ./run_all_mysql.sh
# Comparação (ambos carregados)
PG_CMD="psql -d escola_idiomas -At" MYSQL_CMD="mysql -uroot -N -r -D escola_idiomas" python3 bench.py
```
Detalhes do Workbench em `docs/WORKBENCH.md`.
