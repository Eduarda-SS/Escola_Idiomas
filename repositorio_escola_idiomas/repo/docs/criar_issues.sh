#!/usr/bin/env bash
# Requer GitHub CLI autenticado (gh auth login) dentro do repositório clonado.
set -e
for m in "Sprint 1" "Sprint 2" "Sprint 3"; do gh api repos/:owner/:repo/milestones -f title="$m" >/dev/null; done
for l in modelagem sql testes consultas indices artigo; do gh label create "$l" --force; done
i(){ gh issue create --title "$1" --body "$2" --label "$3" --milestone "$4"; }
i "Levantar problema real" "Descrever dores: planilhas, notas perdidas, turmas lotadas." modelagem "Sprint 1"
i "Modelar diagrama ER" "7 tabelas e cardinalidades." modelagem "Sprint 1"
i "Escrever DDL" "Tipos, PK, FK, UNIQUE, CHECK." sql "Sprint 1"
i "Gatilhos de regra de negócio" "Vagas e habilitação do professor." sql "Sprint 2"
i "Carga sintética" ">300 mil matrículas." sql "Sprint 2"
i "Testes de restrições" "Casos negativos e positivo com evidência." testes "Sprint 2"
i "Consultas analíticas" "C1 a C5." consultas "Sprint 2"
i "Índices e EXPLAIN ANALYZE" "Medir antes/depois." indices "Sprint 3"
i "Redigir artigo SBC" "Usar modelo-tcc-sbc.docx." artigo "Sprint 3"
i "Revisão final e release v1.0" "README, tags e PR final." artigo "Sprint 3"
