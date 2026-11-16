# Metodologia ágil — acompanhamento pelo professor

**Framework:** Scrumban. Quadro Kanban no GitHub Projects com colunas `Backlog → Em andamento → Em revisão → Concluído`.
**Cadência:** 3 sprints de 1 semana, com planejamento na segunda e revisão na sexta (registrada no Pull Request da sprint).
**Definição de pronto (DoD):** script SQL versionado + saída real em `evidencias/` + trecho do artigo atualizado + PR revisado por outro integrante.
**Regras:** branch por issue (`feat/<n>-descricao`), commits no padrão `tipo(escopo): mensagem`, PR obrigatório para `main`.

## Sprints e histórias
| Sprint | Issue | História / tarefa | Pontos |
|---|---|---|---|
| 1 | #1 | Como coordenador, quero levantar o problema real (planilhas, notas perdidas, turmas lotadas) | 2 |
| 1 | #2 | Modelar o diagrama ER (7 tabelas, cardinalidades) | 3 |
| 1 | #3 | Escrever o DDL com tipos e PK/FK/UNIQUE/CHECK | 3 |
| 2 | #4 | Gatilhos de regra de negócio (vagas e habilitação do professor) | 3 |
| 2 | #5 | Carga sintética com volume (>300 mil matrículas) | 2 |
| 2 | #6 | Testes de restrições (casos negativos e positivo) | 3 |
| 2 | #7 | Consultas analíticas C1–C5 | 5 |
| 3 | #8 | Índices + EXPLAIN ANALYZE antes/depois | 3 |
| 3 | #9 | Redigir o artigo no modelo SBC | 5 |
| 3 | #10 | Revisão final, README e release v1.0 | 2 |

Burndown: registrar diariamente os pontos restantes na descrição do milestone.
