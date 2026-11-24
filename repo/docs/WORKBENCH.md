# Usando o MySQL Workbench

1. **Conectar:** abra o Workbench, clique na conexão local (ex.: *Local instance MySQL80*) e digite a senha do usuário `root` definida na instalação do MySQL.
2. **Criar o banco:** numa aba de consulta, rode `CREATE DATABASE escola_idiomas CHARACTER SET utf8mb4;` e depois `USE escola_idiomas;` (ou dê duplo clique no banco no painel *Schemas*).
3. **Executar um script:** `File > Open SQL Script...`, escolha o arquivo e clique no raio (**Execute**, Ctrl+Shift+Enter). Ordem: `01_schema.sql`, `02_carga.sql`, `03_carga_volume.sql` (a última leva de 20 a 60 s).
4. **Ver resultados:** cada `SELECT` abre uma aba em *Result Grid*; as mensagens de erro ficam em *Output* (rodapé).
5. **Testes de restrição (`04_testes_restricoes.sql`):** por padrão o Workbench PARA no primeiro erro. Desmarque o botão *Stop script execution on errors* (ícone da barra do editor) para rodar tudo, ou selecione um bloco e use Ctrl+Enter.
6. **`EXPLAIN ANALYZE`:** no Workbench, o plano aparece como texto em *Result Grid*; use *Form Editor* ou copie a célula. `07_indices.sql` roda uma vez em banco recém-carregado.
7. **Concorrência (T18)**, duas abas: crie uma turma de 1 vaga (`INSERT INTO turma(...) VALUES (3,2,'A1','2031.1',7,'08:00','10:00',1);` e anote o `LAST_INSERT_ID()`).
   Aba A: `START TRANSACTION; INSERT INTO matricula(id_aluno,id_turma) VALUES (40001,<id>); DO SLEEP(20);` (não dê COMMIT ainda).
   Aba B (dentro dos 20 s): `INSERT INTO matricula(id_aluno,id_turma) VALUES (40002,<id>);` — ela espera.
   Aba A: `COMMIT;` — a aba B então falha com "Turma sem vagas". Confira com `SELECT COUNT(*) FROM matricula WHERE id_turma=<id>;` (deve ser 1).
8. **Linha de comando:** o mesmo conjunto roda com `./run_all_mysql.sh` em Git Bash/WSL/Linux/macOS.
