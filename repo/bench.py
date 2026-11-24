#!/usr/bin/env python3
"""Benchmark comparativo PostgreSQL x MySQL (mediana de N execucoes de EXPLAIN ANALYZE).
Variaveis de ambiente: PG_CMD e MYSQL_CMD (comandos base, ex.: 'psql -d escola_idiomas -At' e 'mysql -uroot -N escola_idiomas')."""
import subprocess, re, json, statistics, os, sys, shlex
N = int(os.environ.get('RUNS', 7))
PG = shlex.split(os.environ.get('PG_CMD', 'psql -d escola_idiomas -At'))
MY = shlex.split(os.environ.get('MYSQL_CMD', 'mysql -uroot -N -r -D escola_idiomas'))

def run(cmd, sql):
    flag = '-c' if 'psql' in ' '.join(cmd) else '-e'
    r = subprocess.run(cmd + [flag, sql], capture_output=True, text=True)
    if r.returncode: raise RuntimeError(r.stderr)
    return r.stdout

def pg_time(sql):
    out = run(PG, f"EXPLAIN (ANALYZE, COSTS OFF) {sql}")
    ms = float(re.search(r'Execution Time: ([\d.]+) ms', out).group(1))
    return ms, out
def my_time(sql):
    out = run(MY, f"EXPLAIN ANALYZE {sql}")
    first = out.strip().split('\n')[0]
    m = re.search(r'actual time=[\d.]+\.\.([\d.]+) rows=\d+ loops=(\d+)', first)
    return float(m.group(1)), out
def plan_pg(out):
    for l in out.split('\n'):
        if re.search(r'Scan|Index', l): return re.sub(r'\s*\(actual.*', '', l).replace('->','').strip()
    return '?'
def plan_my(out):
    for l in out.split('\n'):
        if re.search(r'scan|lookup|Table|Covering', l, re.I) and 'EXPLAIN' not in l:
            return re.sub(r'\s*\(cost.*', '', l).replace('->','').strip()
    return '?'
def bench(fn, sql):
    fn(sql)  # aquecimento
    ts = [fn(sql)[0] for _ in range(N)]
    return statistics.median(ts), min(ts), max(ts), fn(sql)[1]

def parse_queries(path, kind):
    t = open(path).read(); q = {}
    if kind == 'pg':
        for blk in re.split(r"(?=\\echo '--- C\d+:)", t)[1:]:
            k = re.match(r"\\echo '--- (C\d+)", blk).group(1)
            body = '\n'.join(l for l in blk.split('\n')[1:])
            q[k] = body.strip().rstrip(';')
    else:
        for blk in re.split(r"(?=SELECT 'C\d+:)", t)[1:]:
            k = re.match(r"SELECT '(C\d+)", blk).group(1)
            body = blk.split(';', 1)[1]
            q[k] = body.strip().rstrip(';')
    return q

IDX = {  # (nome, sql com {m},{a},{t} = nomes das tabelas)
 'Q1': ("matriculas de um aluno",  "SELECT * FROM {m} WHERE id_aluno=12345"),
 'Q2': ("avaliacoes de uma matricula", "SELECT * FROM {a} WHERE id_matricula=150000"),
 'Q3': ("turmas de um semestre",   "SELECT * FROM {t} WHERE semestre='2026.1'"),
 'Q4': ("matriculas ativas de uma turma", "SELECT COUNT(*) FROM {m} WHERE id_turma=11 AND situacao='ATIVA'"),
}
res = {'indices': {}, 'consultas': {}}
raw = {'pg': [], 'mysql': []}
systems = {'pg': (pg_time, plan_pg, PG), 'mysql': (my_time, plan_my, MY)}

def stage(sysname, label, tables):
    fn, pl, _ = systems[sysname]
    for k, (nm, tpl) in IDX.items():
        sql = tpl.format(**tables)
        med, lo, hi, out = bench(fn, sql)
        res['indices'].setdefault(k, {}).setdefault(sysname, {})[label] = dict(ms=med, min=lo, max=hi, plano=pl(out))
        raw[sysname].append(f"### {sysname} / {label} / {k}: {sql}\n{out}")

# --- copias sem nenhum indice (estagio S0)
run(PG, "DROP TABLE IF EXISTS matricula_sem, avaliacao_sem, turma_sem; CREATE TABLE matricula_sem AS SELECT * FROM matricula; CREATE TABLE avaliacao_sem AS SELECT * FROM avaliacao; CREATE TABLE turma_sem AS SELECT * FROM turma; ANALYZE;")
run(MY, "DROP TABLE IF EXISTS matricula_sem, avaliacao_sem, turma_sem; CREATE TABLE matricula_sem AS SELECT * FROM matricula; CREATE TABLE avaliacao_sem AS SELECT * FROM avaliacao; CREATE TABLE turma_sem AS SELECT * FROM turma; ANALYZE TABLE matricula_sem, avaliacao_sem, turma_sem;")
# --- limpar indices explicitos de execucoes anteriores
run(PG, "DROP INDEX IF EXISTS idx_matricula_turma_sit, idx_turma_semestre;")
# MySQL: o indice composto vira o indice de suporte da FK id_turma; para remove-lo e preciso recriar a FK
try:
    run(MY, "ALTER TABLE matricula DROP FOREIGN KEY fk_mat_turma, DROP INDEX idx_matricula_turma_sit")
    run(MY, "ALTER TABLE matricula ADD CONSTRAINT fk_mat_turma FOREIGN KEY (id_turma) REFERENCES turma(id_turma) ON DELETE RESTRICT")
except RuntimeError: pass
try: run(MY, "DROP INDEX idx_turma_semestre ON turma")
except RuntimeError: pass
run(MY, "ANALYZE TABLE matricula, turma")
for s in systems:
    stage(s, 'S0_sem_indice', dict(m='matricula_sem', a='avaliacao_sem', t='turma_sem'))
    stage(s, 'S1_esquema',    dict(m='matricula', a='avaliacao', t='turma'))
# --- indices explicitos (S2)
run(PG, "CREATE INDEX idx_matricula_turma_sit ON matricula(id_turma, situacao); CREATE INDEX idx_turma_semestre ON turma(semestre); ANALYZE matricula; ANALYZE turma;")
run(MY, "CREATE INDEX idx_matricula_turma_sit ON matricula(id_turma, situacao); CREATE INDEX idx_turma_semestre ON turma(semestre); ANALYZE TABLE matricula, turma;")
for s in systems:
    stage(s, 'S2_indices', dict(m='matricula', a='avaliacao', t='turma'))

# --- consultas analiticas C1-C5
qpg = parse_queries('sql/postgres/06_consultas.sql', 'pg')
qmy = parse_queries('sql/mysql/06_consultas.sql', 'mysql')
for k in sorted(qpg):
    for s, q in (('pg', qpg), ('mysql', qmy)):
        fn, pl, _ = systems[s]
        med, lo, hi, out = bench(fn, q[k])
        res['consultas'].setdefault(k, {})[s] = dict(ms=med, min=lo, max=hi)
        raw[s].append(f"### {s} / {k}\n{out}")

# --- tamanhos
sz = {}
sz['pg'] = run(PG, "SELECT pg_size_pretty(pg_database_size(current_database())), pg_size_pretty(pg_total_relation_size('matricula')), pg_size_pretty(pg_indexes_size('matricula')), pg_size_pretty(pg_total_relation_size('avaliacao')), pg_size_pretty(pg_indexes_size('avaliacao'))").strip()
sz['mysql'] = run(MY, "SELECT table_name, ROUND(data_length/1048576,1) dados_mb, ROUND(index_length/1048576,1) indices_mb FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN ('matricula','avaliacao','aluno','turma') ORDER BY table_name").strip()
res['tamanhos'] = sz
run(PG, "DROP TABLE matricula_sem, avaliacao_sem, turma_sem;"); run(MY, "DROP TABLE matricula_sem, avaliacao_sem, turma_sem;")
os.makedirs('evidencias/comparacao', exist_ok=True)
json.dump(res, open('evidencias/comparacao/resultados.json', 'w'), indent=1, ensure_ascii=False)
open('evidencias/comparacao/planos_postgres.txt', 'w').write('\n'.join(raw['pg']))
open('evidencias/comparacao/planos_mysql.txt', 'w').write('\n'.join(raw['mysql']))
print(json.dumps(res, indent=1, ensure_ascii=False))
