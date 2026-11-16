# Escola de Idiomas — Projeto de Banco de Dados (Unidade II, Tema 8)

Banco relacional em PostgreSQL 16 para turmas por idioma, matrículas e notas de avaliação.

## Estrutura
| Pasta/arquivo | Conteúdo |
|---|---|
| `sql/01_schema.sql` | DDL: tabelas, tipos, PK/FK/UNIQUE/CHECK e 2 gatilhos |
| `sql/02_carga.sql`, `03_carga_volume.sql` | Carga sintética (50 mil alunos, ~302 mil matrículas, ~904 mil avaliações) |
| `sql/04_testes_restricoes.sql` | 17 testes (16 negativos + 1 positivo) de restrições e gatilhos |
| `sql/05_tipos.sql` | Catálogo de tipos e restrições (information_schema / pg_constraint) |
| `sql/06_consultas.sql` | 5 consultas analíticas (boletim, ocupação, aprovação, alerta, custo) |
| `sql/07_indices.sql` | EXPLAIN ANALYZE antes/depois dos índices |
| `evidencias/` | Saída bruta de cada script, gerada pela execução real |
| `docs/` | Diagrama ER (`er.dot`/`er.png`), gráfico de índices, metodologia ágil |

## Como reproduzir
```bash
createdb escola_idiomas
./run_all.sh
```

## Metodologia ágil
Kanban + sprints de 1 semana. Veja `docs/AGILE.md` e `docs/criar_issues.sh` (cria milestones, labels e issues via GitHub CLI).
Acompanhamento do professor: aba **Projects** (quadro "Escola de Idiomas") e **Insights → Pulse** do repositório.
