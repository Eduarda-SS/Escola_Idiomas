# Scripts SQL — mesma numeração nos dois SGBDs

`sql/postgres/` e `sql/mysql/` têm os mesmos 10 arquivos. A saída de cada um fica em `evidencias/postgres/` ou `evidencias/mysql/` com o mesmo nome (.txt).

| Nº | Arquivo | O que faz | Executar quando |
|---|---|---|---|
| 01 | `01_schema.sql` | Cria 7 tabelas, restrições e gatilhos (apaga e recria) | primeiro |
| 02 | `02_carga.sql` | Carga base: idiomas, professores, 160 turmas, 50 mil alunos, matrículas e notas recentes | após 01 |
| 03 | `03_carga_volume.sql` | Volume: 4.400 turmas históricas, 300 mil matrículas, 900 mil avaliações | após 02 |
| 04 | `04_testes_restricoes.sql` | T1–T17: 15 violações, cascata e controle positivo | após 03 |
| 05 | `05_tipos.sql` | Catálogo de tipos e restrições | após 01 |
| 06 | `06_consultas.sql` | Consultas C1–C5 | após 03 |
| 07 | `07_indices.sql` | Planos sem índice / esquema / com índices | após 03, num banco sem índices extras |
| 08 | `08_concorrencia.sh` | T18: duas sessões disputando a última vaga | após 03 (bash) |
| 09 | `09_diferencas.sql` | PostgreSQL: recursos aceitos. MySQL: erros que provam a diferença (D1–D4) | após 03 |
| 10 | `10_gatilho_sem_trava.sql` | Controle: gatilho sem `FOR UPDATE`; rode o 08 e depois restaure com o 01 | opcional |

Dialeto: o PostgreSQL usa `\echo` e `generate_series`; o MySQL usa `SELECT 'texto'` como marcador e uma tabela auxiliar de números.
