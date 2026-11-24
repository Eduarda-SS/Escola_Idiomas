// Gera o artigo em .docx a partir dos arquivos de evidência (node docs/build_article.js)
const fs = require('fs');
const path = require('path');
const R = path.join(__dirname, '..');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
  AlignmentType, WidthType, BorderStyle, ShadingType, Footer, PageNumber,
} = require('docx');

const C = JSON.parse(fs.readFileSync(`${R}/docs/consultas.json`, 'utf8'));
const B = JSON.parse(fs.readFileSync(`${R}/evidencias/comparacao/resultados.json`, 'utf8'));
const T = JSON.parse(fs.readFileSync(`${R}/docs/testes.json`, 'utf8'));
const TNR = 'Times New Roman', ARIAL = 'Arial';

// ---------- formatação ----------
const f = (ms) => {
  let s;
  if (ms >= 100) s = ms.toFixed(0); else if (ms >= 10) s = ms.toFixed(1);
  else if (ms >= 1) s = ms.toFixed(2); else if (ms >= 0.1) s = ms.toFixed(3); else s = ms.toFixed(4).replace(/0+$/, '').replace(/\.$/, '');
  return s.replace('.', ',');
};
const x = (a, b) => { const r = a / b; return r >= 100 ? Math.round(r / 10) * 10 : r >= 10 ? Math.round(r) : r.toFixed(1).replace('.', ','); };
const I = B.indices, K = B.consultas;
const ms = (q, s, st) => I[q][s][st].ms;

// ---------- helpers ----------
const run = (t, o = {}) => new TextRun({ text: t, font: o.font || TNR, size: o.size || 24, bold: o.bold, italics: o.italics });
const P = (children, o = {}) => new Paragraph({
  alignment: o.align || AlignmentType.JUSTIFIED, spacing: { after: o.after ?? 120, before: o.before ?? 0, line: 276 },
  indent: o.noIndent ? undefined : { firstLine: 567 }, keepNext: o.keepNext,
  children: Array.isArray(children) ? children : [run(children)],
});
const txt = (t) => P(t);
const mixed = (parts) => P(parts.map(p => typeof p === 'string' ? run(p) : run(p.t, p)));
const H1 = (t) => new Paragraph({ keepNext: true, spacing: { before: 240, after: 120 }, children: [run(t, { bold: true })] });
const H2 = (t) => new Paragraph({ keepNext: true, spacing: { before: 200, after: 100 }, children: [run(t, { bold: true, italics: true })] });
const cap = (t, above) => new Paragraph({
  alignment: AlignmentType.CENTER, keepNext: above, spacing: { before: above ? 160 : 60, after: above ? 80 : 200 },
  children: [new TextRun({ text: t, font: ARIAL, size: 20, bold: true })],
});
const border = { style: BorderStyle.SINGLE, size: 4, color: '999999' };
const borders = { top: border, bottom: border, left: border, right: border };
function table(headers, rows, widths, o = {}) {
  const sum = widths.reduce((a, b) => a + b, 0);
  const mk = (t, w, head, align) => new TableCell({
    width: { size: w, type: WidthType.DXA }, borders,
    shading: head ? { fill: 'DCE6F1', type: ShadingType.CLEAR, color: 'auto' } : undefined,
    margins: { top: 40, bottom: 40, left: 70, right: 70 },
    children: [new Paragraph({ alignment: align || AlignmentType.LEFT, children: [new TextRun({ text: String(t), font: ARIAL, size: o.size || 17, bold: head })] })],
  });
  return new Table({
    width: { size: sum, type: WidthType.DXA }, columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, cantSplit: true, children: headers.map((h, i) => mk(h, widths[i], true, (o.right || []).includes(i) ? AlignmentType.RIGHT : AlignmentType.LEFT)) }),
      ...rows.map(r => new TableRow({ cantSplit: true, children: r.map((c, i) => mk(c, widths[i], false, (o.right || []).includes(i) ? AlignmentType.RIGHT : AlignmentType.LEFT)) })),
    ],
  });
}
const img = (p, w, h) => new Paragraph({
  alignment: AlignmentType.CENTER, spacing: { before: 120, after: 0 }, keepNext: true,
  children: [new ImageRun({ type: 'png', data: fs.readFileSync(p), transformation: { width: w, height: h }, altText: { title: 'figura', description: 'figura do artigo', name: 'fig' } })],
});
const spacer = () => new Paragraph({ spacing: { after: 0 }, children: [] });
const fromC = (k) => ({ h: C[k][0], r: C[k].slice(1) });

const children = [];
const add = (...a) => a.flat().forEach(e => children.push(e));

// ---------- cabeçalho ----------
add(
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 120 }, children: [run('Banco de Dados para uma Escola de Idiomas: Modelagem, Restrições, Índices e Comparação entre PostgreSQL e MySQL Validada por Testes', { bold: true, size: 32 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 240 }, children: [run('Database Design for a Language School: Modeling, Constraints, Indexes and a Test-Validated Comparison of PostgreSQL and MySQL', { bold: true, italics: true, size: 26 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 60 }, children: [run('[Nome do Aluno 1]¹, [Nome do Aluno 2]¹, [Nome do Aluno 3]¹', { bold: true })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 0 }, children: [run('¹[Curso/Departamento — Nome da Instituição]', { size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 0 }, children: [run('Aracaju, Sergipe – SE', { size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 240 }, children: [run('{email.aluno1,email.aluno2,email.aluno3}@dominio.edu.br', { size: 22 })] }),
);

add(
  P([run('Resumo.  ', { bold: true, italics: true }), run(`Escolas de idiomas costumam controlar turmas, matrículas e notas em planilhas, o que gera turmas acima da capacidade, professores alocados em idiomas que não dominam e boletins inconsistentes. Este trabalho projeta um banco relacional de sete tabelas, implementa-o em PostgreSQL 16 e em MySQL 8.0 (scripts compatíveis com o MySQL Workbench) e compara os dois por testes executados na mesma máquina. Com 50 mil alunos, 302 mil matrículas e cerca de 906 mil avaliações sintéticas, aplicamos 18 testes em cada SGBD (15 tentativas de violação de regras, 1 de cascata, 1 controle positivo e 1 de concorrência), cinco consultas analíticas e medições de plano de execução com mediana de 7 execuções. Os dois SGBDs rejeitaram as 15 violações e aceitaram o controle positivo; no MySQL a regra de data de nascimento exigiu gatilhos, porque o CHECK com CURRENT_DATE é recusado. Em um teste de controle, sem bloqueio de linha duas sessões simultâneas ocuparam a única vaga de uma turma nos dois SGBDs; com o bloqueio, só uma conseguiu. Em varreduras completas o MySQL foi de ${x(ms('Q1', 'mysql', 'S0_sem_indice'), ms('Q1', 'pg', 'S0_sem_indice'))} a ${x(ms('Q2', 'mysql', 'S0_sem_indice'), ms('Q2', 'pg', 'S0_sem_indice'))} vezes mais lento; com índices ambos ficaram abaixo de 0,15 ms nas buscas pontuais. Nas consultas analíticas, o PostgreSQL com a configuração padrão foi ${x(K.C2.pg.ms, K.C2.mysql.ms)} vezes mais lento em C2, e o ajuste de random_page_cost corrigiu o problema, mas foi ${x(K.C3.mysql.ms, K.C3.pg.ms)} vezes mais rápido em C3. Concluímos que ambos atendem ao problema, com diferenças de dialeto e de plano que dependem da carga de trabalho.`, { italics: true })], { noIndent: true }),
  P([run('Palavras-chave: ', { bold: true }), run('banco de dados relacional, PostgreSQL, MySQL, integridade referencial, índices, escola de idiomas.')], { noIndent: true }),
  P([run('Abstract.  ', { bold: true, italics: true }), run(`Language schools often track classes, enrollments and grades in spreadsheets, causing overbooked classes, teachers assigned to languages they do not teach and inconsistent report cards. This work designs a seven-table relational database, implements it in PostgreSQL 16 and MySQL 8.0 (scripts compatible with MySQL Workbench) and compares both through tests run on the same machine. With 50,000 students, 302,000 enrollments and about 906,000 synthetic assessments, we ran 18 tests per DBMS (15 rule-violation attempts, 1 cascade, 1 positive control and 1 concurrency test), five analytical queries and execution-plan measurements using the median of 7 runs. Both systems rejected all 15 violations and accepted the positive control; in MySQL the birth-date rule required triggers because a CHECK using CURRENT_DATE is rejected. In a control test, without row locking two concurrent sessions took the only seat of a class in both systems; with locking, only one succeeded. On full scans MySQL was ${x(ms('Q1', 'mysql', 'S0_sem_indice'), ms('Q1', 'pg', 'S0_sem_indice'))} to ${x(ms('Q2', 'mysql', 'S0_sem_indice'), ms('Q2', 'pg', 'S0_sem_indice'))} times slower; with indexes both stayed below 0.15 ms on point lookups. On analytical queries, PostgreSQL with default settings was ${x(K.C2.pg.ms, K.C2.mysql.ms)} times slower on C2, which the random_page_cost setting fixed, but it was ${x(K.C3.mysql.ms, K.C3.pg.ms)} times faster on C3. Both meet the problem's needs, with dialect and plan differences that depend on the workload.`, { italics: true })], { noIndent: true }),
  P([run('Keywords: ', { bold: true }), run('relational database, PostgreSQL, MySQL, referential integrity, indexes, language school.')], { noIndent: true }),
);

// ---------- 1 ----------
add(H1('1. Introdução'),
  txt('Uma escola de idiomas opera com poucos conceitos, mas com regras que se cruzam: cada turma pertence a um idioma e a um nível, é conduzida por um professor habilitado, tem número limitado de vagas e recebe alunos que são avaliados ao longo do semestre. Quando esses dados vivem em planilhas, as regras dependem da atenção de quem digita. Três falhas são típicas: (i) a secretaria matricula além da capacidade da sala; (ii) um professor é escalado para um idioma que não leciona ou para dois horários simultâneos; (iii) uma nota inválida (por exemplo, 11) ou duplicada entra no boletim e só é percebida no fim do semestre.'),
  txt('O objetivo geral é projetar um banco de dados que impeça essas falhas por construção e provar, com testes executados, que ele funciona. Os objetivos específicos são: modelar a solução e documentar as decisões de tipos e restrições; testar cada restrição com um caso que a viole; responder a perguntas de gestão com consultas SQL; medir o efeito de índices sobre um volume realista; implementar a mesma solução em PostgreSQL e em MySQL (MySQL Workbench) e comparar, por testes, as diferenças de dialeto, de integridade e de desempenho; e acompanhar o desenvolvimento por uma metodologia ágil versionada no GitHub.'),
  txt('A Seção 2 apresenta a base conceitual. A Seção 3 descreve o ambiente e o método de teste. A Seção 4 traz a arquitetura, as decisões, os resultados dos testes nos dois SGBDs e a comparação entre eles. A Seção 5 conclui e discute limitações.'),
);

// ---------- 2 ----------
add(H1('2. Trabalhos Relacionados'),
  txt('A base teórica é o modelo relacional de Codd [1], no qual a integridade é expressa por chaves e restrições declaradas no esquema, e não por disciplina da aplicação. Elmasri e Navathe [2] e Silberschatz, Korth e Sudarshan [3] descrevem a modelagem entidade-relacionamento, a normalização até a terceira forma normal e o papel dos índices B-tree na redução do custo de acesso; esses textos orientam o desenho das sete tabelas e a escolha de tabelas associativas para relações N:N.'),
  txt('As documentações oficiais do PostgreSQL [4] e do MySQL [5] são a referência para o comportamento observado nos testes: criação de índices para PRIMARY KEY e UNIQUE, tratamento de chaves estrangeiras, restrições CHECK, gatilhos, bloqueio de linha com FOR UPDATE e o formato de EXPLAIN ANALYZE. O MySQL Workbench [6] é a ferramenta gráfica oficial para executar os scripts do lado do MySQL. Para os níveis de proficiência das turmas adotamos a escala A1 a C2 do Quadro Europeu Comum de Referência [7]. A organização em sprints curtas com quadro Kanban segue os princípios do Manifesto Ágil [8].'),
  txt('A contribuição deste trabalho em relação a esses textos é prática: aplicar os conceitos a um domínio concreto, executar a mesma solução em dois SGBDs e substituir a afirmação por evidência, com cada decisão acompanhada de um teste cujo resultado está no repositório.'),
);

// ---------- 3 ----------
add(H1('3. Metodologia'),
  H2('3.1 Ambiente e volume de dados'),
  txt('Os dois SGBDs foram instalados na mesma máquina virtual (1 vCPU, cerca de 4 GB de RAM, Ubuntu 24.04) e executados com a configuração padrão, incluindo 128 MB de memória de cache em cada um (shared_buffers no PostgreSQL e innodb_buffer_pool_size no MySQL). Os dados são sintéticos, gerados por SQL, sem dados pessoais reais. A lógica de geração é a mesma nos dois, mas a ordem de atribuição de identificadores e os valores aleatórios das notas diferem, de modo que as bases não são idênticas linha a linha (por exemplo, 1.005 matrículas ativas em 2026.1 no PostgreSQL e 997 no MySQL). A Tabela 1 resume o ambiente.'),
  cap('Tabela 1. Ambiente de execução e volume de dados carregado', true),
  table(['Item', 'PostgreSQL', 'MySQL'], [
    ['Versão', '16.15', '8.0.46'],
    ['Cliente usado na execução registrada', 'psql', 'mysql (linha de comando)'],
    ['Alunos / professores / idiomas', '50.000 / 20 / 5', '50.000 / 20 / 5'],
    ['Turmas (2020.1 a 2026.1)', '4.560', '4.560'],
    ['Matrículas', '302.226', '302.226'],
    ['Avaliações', '906.454', '906.482'],
  ], [3500, 2500, 2504]),
  spacer(),
  H2('3.2 Procedimento de teste'),
  txt('Cada afirmação do artigo vira um script em sql/postgres ou sql/mysql e produz um arquivo de saída em evidencias/. Os testes de restrição inserem ou alteram uma linha que viola a regra e registram o erro do SGBD; um controle positivo confirma que dados válidos são aceitos. Testes com efeito colateral rodam dentro de transação revertida. Os tempos de consulta vêm de EXPLAIN ANALYZE, com uma execução de aquecimento descartada e a mediana de 7 execuções (script bench.py). Para o estágio “sem índice” criamos, em cada SGBD, cópias das tabelas sem nenhuma chave; o estágio “esquema” usa as tabelas reais com as chaves de 01_schema; o estágio “índices” adiciona dois índices explícitos.'),
  txt('Os scripts do MySQL foram escritos para o MySQL Workbench (arquivos .sql abertos com File > Open SQL Script, com orientações em docs/WORKBENCH.md). A execução registrada neste artigo usou o cliente de linha de comando mysql com os mesmos arquivos; as capturas de tela da interface do Workbench devem ser anexadas pelo grupo.'),
  H2('3.3 Metodologia ágil'),
  txt('O trabalho foi organizado em três sprints de uma semana com quadro Kanban (Backlog, Em andamento, Em revisão, Concluído) no GitHub Projects. As histórias, seus pontos e a definição de pronto estão em docs/AGILE.md, e docs/criar_issues.sh cria milestones, labels e issues com o GitHub CLI. Uma história só é concluída quando traz o script SQL, a saída real em evidencias/ e o trecho do artigo, e quando um segundo integrante revisa o Pull Request. O professor acompanha o progresso pelas issues, pelo quadro e pelo histórico de commits.'),
);

// ---------- 4 ----------
add(H1('4. Desenvolvimento e Resultados'),
  H2('4.1 Arquitetura do banco'),
  txt('O modelo tem sete tabelas (Figura 1). ALUNO, PROFESSOR e IDIOMA são entidades independentes. TURMA liga um idioma a um professor em um semestre, dia e horário. MATRICULA liga aluno a turma e guarda a situação (ATIVA, TRANCADA, CANCELADA ou CONCLUIDA). AVALIACAO guarda cada nota por matrícula e tipo (PROVA1, PROVA2, ORAL, TRABALHO). PROFESSOR_IDIOMA resolve a relação N:N entre professores e os idiomas em que são habilitados. O mesmo modelo foi implementado nos dois SGBDs.'),
  img(`${R}/docs/er.png`, 560, 266),
  cap('Figura 1. Diagrama entidade-relacionamento da escola de idiomas (cardinalidades 1:N)'),
  txt('O esquema está na terceira forma normal. A média do aluno não é gravada, porque seria um dado derivado que ficaria desatualizado a cada nova nota; ela é calculada na consulta C1. Notas ficam em tabela própria, e não em colunas nota1, nota2, nota3, para que um novo tipo de avaliação não exija alterar a estrutura.'),

  H2('4.2 Decisões de tipos'),
  txt('A Tabela 2 resume os tipos e a razão de cada um, com o equivalente em cada SGBD. O catálogo de cada banco confirma a criação conforme as decisões (arquivos evidencias/postgres/05_tipos.txt e evidencias/mysql/05_tipos.txt).'),
  cap('Tabela 2. Principais tipos de dados e justificativa', true),
  table(['Coluna', 'PostgreSQL', 'MySQL', 'Justificativa'], [
    ['aluno.cpf', 'CHAR(11)', 'CHAR(11)', 'Tamanho fixo; guarda zeros à esquerda'],
    ['avaliacao.nota', 'NUMERIC(4,2)', 'DECIMAL(4,2)', 'Decimal exato; evita erro de arredondamento na média'],
    ['turma.nivel', 'VARCHAR(2)+CHECK', 'VARCHAR(2)+CHECK', 'Conjunto fixo A1 a C2 (escala CEFR)'],
    ['turma.semestre', 'CHAR(6)+CHECK regex', 'CHAR(6)+CHECK REGEXP', 'Formato AAAA.S validado'],
    ['turma.hora_inicio/fim', 'TIME', 'TIME', 'Permite CHECK hora_fim > hora_inicio'],
    ['turma.vagas', 'SMALLINT (1 a 30)', 'SMALLINT (1 a 30)', 'Faixa pequena; limita erro de digitação'],
    ['chaves surrogate', 'SERIAL / SMALLSERIAL', 'INT AUTO_INCREMENT', 'Mesma função; sintaxe diferente'],
    ['matricula.data_matricula', 'DEFAULT CURRENT_DATE', 'DEFAULT (CURRENT_DATE)', 'No MySQL a expressão exige parênteses'],
  ], [2000, 1900, 1900, 2704]),
  spacer(),

  H2('4.3 Restrições e gatilhos testados'),
  txt('O esquema do PostgreSQL declara 7 chaves primárias, 7 estrangeiras, 7 UNIQUE e 12 CHECKs, mais 2 gatilhos. O do MySQL declara 7, 7, 7 e 11 CHECKs, mais 5 gatilhos (contagens obtidas dos catálogos de cada SGBD). A diferença vem da regra de data de nascimento, tratada na Seção 4.4. Para cada regra, o teste correspondente tenta violá-la. A Tabela 3 mostra o resultado observado em evidencias/postgres/04_testes_restricoes.txt, evidencias/mysql/04_testes_restricoes.txt e nos arquivos 08_concorrencia de cada pasta.'),
  cap('Tabela 3. Testes de restrições, gatilhos e concorrência nos dois SGBDs', true),
  table(['Teste', 'Ação tentada', 'PostgreSQL (rejeitado por)', 'MySQL (rejeitado por)'], [
    ['T1', 'CPF com letra', T.pg.T1, T.my.T1],
    ['T2', 'CPF já cadastrado', T.pg.T2, T.my.T2],
    ['T3', 'E-mail sem @', T.pg.T3, T.my.T3],
    ['T4', 'Nascimento em 2999', T.pg.T4 + ' (CHECK)', T.my.T4 + ' (gatilho)'],
    ['T5', 'Nome nulo', T.pg.T5, T.my.T5],
    ['T6', 'Nota 11', T.pg.T6, T.my.T6],
    ['T7', 'Segunda PROVA1 na matrícula', T.pg.T7, T.my.T7],
    ['T8', 'Aluno inexistente (FK)', T.pg.T8, T.my.T8],
    ['T9', 'Repetir matrícula aluno/turma', T.pg.T9, T.my.T9],
    ['T10', 'Nível "Z9"', T.pg.T10, T.my.T10],
    ['T11', 'Hora fim antes do início', T.pg.T11, T.my.T11],
    ['T12', 'Professor não habilitado (gatilho)', 'mensagem do gatilho', T.my.T12],
    ['T13', 'Professor com choque de horário', 'UNIQUE (professor, semestre, dia, hora)', T.my.T13],
    ['T14', 'Apagar turma com matrículas', T.pg.T14, T.my.T14],
    ['T15', '3 matrículas em turma de 2 vagas', 'terceira rejeitada pelo gatilho', 'terceira rejeitada: erro 1644 (gatilho)'],
    ['T16', 'Apagar matrícula com 4 avaliações', '4 antes, 0 depois (CASCADE)', '4 antes, 0 depois (CASCADE)'],
    ['T17', 'Aluno válido (controle positivo)', 'aceito', 'aceito'],
    ['T18', 'Duas sessões, 1 vaga, com trava', '1 matrícula para 1 vaga', '1 matrícula para 1 vaga'],
  ], [600, 2500, 2700, 2704], { size: 16 }),
  spacer(),
  txt('Três achados do processo de teste merecem registro. Primeiro, a versão inicial de T10 não testou o CHECK de nível: o gatilho de habilitação do professor dispara antes das restrições CHECK e rejeitou a linha por outro motivo. Só com um professor habilitado o teste passou a exercitar a restrição de nível, e por isso T10 usa o idioma 2 com o professor 1. Segundo, a versão inicial do gatilho de vagas contava as matrículas sem travar a turma. A correção foi adicionar SELECT ... FOR UPDATE sobre a linha da turma dentro do gatilho. Para provar que a trava é necessária e não apenas supor, repetimos T18 com o gatilho sem a trava (arquivos 10_gatilho_sem_trava e 10_concorrencia_sem_trava): nos dois SGBDs a turma de 1 vaga terminou com 2 matrículas ativas; com a trava, terminou com 1. Terceiro, os 15 primeiros testes são tentativas de violação; T16 verifica uma cascata permitida e T17 é o controle positivo.'),

  H2('4.4 Diferenças de dialeto encontradas na portabilidade'),
  txt('Portar o esquema para o MySQL revelou diferenças que alteraram o código, e cada uma foi reproduzida em teste (Tabela 4; arquivos evidencias/postgres/09_diferencas.txt, evidencias/mysql/09_diferencas.txt, evidencias/comparacao/autoincrement_lacunas.txt e resultados do benchmark).'),
  cap('Tabela 4. Diferenças de comportamento observadas entre PostgreSQL e MySQL', true),
  table(['Tema', 'PostgreSQL', 'MySQL 8.0'], [
    ['CHECK com CURRENT_DATE', 'Aceito (data de nascimento no passado)', 'Recusado: erro 3814 “disallowed function: curdate”; regra reescrita com 2 gatilhos (INSERT e UPDATE)'],
    ['Agregação condicional', 'count(*) FILTER (WHERE ...)', 'Erro de sintaxe 1064; usa SUM(condição)'],
    ['Inserção ignorando duplicatas', 'ON CONFLICT DO NOTHING', 'Erro de sintaxe 1064; usa INSERT IGNORE'],
    ['Gatilho com FOR UPDATE em turma durante INSERT ... SELECT FROM turma', 'Permitido', 'Erro 1442; a carga precisou materializar as turmas em tabela temporária'],
    ['Índice automático em chave estrangeira', 'Não cria (Q4 no estágio “esquema” fez varredura completa)', 'Cria (Q4 no estágio “esquema” usou o índice fk_mat_turma)'],
    ['Identificadores em INSERT ... SELECT', 'Contíguos (turmas históricas 161 a 4560)', 'Com lacunas (turmas históricas 256 a 4655); a carga assumia ids contíguos e o INSERT IGNORE descartou matrículas em silêncio até mapearmos por posição'],
    ['Índice composto e FK', 'Independentes', 'O índice (id_turma, situacao) passou a servir de suporte à FK id_turma (SHOW INDEX não listou outro índice); removê-lo exigiu recriar a FK'],
  ], [2300, 2700, 3504]),
  spacer(),
  txt('O achado sobre identificadores merece atenção: sem a conferência da contagem de linhas, a carga do MySQL teria parecido bem-sucedida com 293.513 matrículas históricas em vez de 300.000. A conferência dos volumes é parte do procedimento de teste.'),

  H2('4.5 Consultas de gestão'),
  txt('Cinco consultas respondem perguntas reais da secretaria e da coordenação (sql/postgres/06_consultas.sql e a versão portada em sql/mysql). As tabelas reproduzem a saída do PostgreSQL sobre a carga completa; a versão MySQL produz as mesmas colunas, com valores diferentes onde há aleatoriedade ou atribuição de identificadores distinta (Seção 3.1).'),
  mixed([{ t: 'C1 — Boletim do aluno 100. ', bold: true }, 'Une aluno, matrícula, turma, idioma e avaliação, calcula a média e classifica com aprovação a partir de 7,0 (critério adotado pelo grupo).']),
  cap('Tabela 5. Resultado de C1: boletim do aluno 100 (PostgreSQL)', true),
  table(fromC('C1').h, fromC('C1').r, [1500, 1400, 900, 1300, 1100, 2304], { right: [4] }),
  spacer(),
  mixed([{ t: 'C2 — Ocupação das turmas de 2026.1. ', bold: true }, 'Conta apenas matrículas ativas por turma e calcula o percentual de vagas ocupadas.']),
  cap('Tabela 6. Resultado de C2: turmas mais ocupadas em 2026.1 (5 primeiras, PostgreSQL)', true),
  table(fromC('C2').h, fromC('C2').r, [1000, 1300, 800, 1900, 800, 900, 1804], { right: [0, 4, 5, 6] }),
  spacer(),
  mixed([{ t: 'C3 — Desempenho por idioma. ', bold: true }, 'Agrega matrículas concluídas e mostra média geral e taxa de aprovação.']),
  cap('Tabela 7. Resultado de C3: média e aprovação por idioma (PostgreSQL)', true),
  table(fromC('C3').h, fromC('C3').r, [2200, 1800, 2100, 2404], { right: [1, 2, 3] }),
  spacer(),
  mixed([{ t: 'C4 — Alerta pedagógico. ', bold: true }, 'Lista alunos de 2026.1 com média parcial abaixo de 5,0 para a coordenação agir antes do fim do semestre.']),
  cap('Tabela 8. Resultado de C4: alunos com média abaixo de 5,0 em 2026.1 (5 primeiros, PostgreSQL)', true),
  table(fromC('C4').h, fromC('C4').r, [3200, 2300, 3004], { right: [1, 2] }),
  spacer(),
  mixed([{ t: 'C5 — Carga horária e custo semanal por professor. ', bold: true }, 'Soma as horas das turmas de 2026.1 e multiplica pelo valor da hora.']),
  cap('Tabela 9. Resultado de C5: carga e custo semanal por professor (5 primeiros, PostgreSQL)', true),
  table(fromC('C5').h, fromC('C5').r, [2400, 1800, 2000, 2304], { right: [1, 2, 3] }),
  spacer(),
  txt('Como as notas foram geradas com média próxima de 7, a taxa de aprovação de cerca de 50% em todos os idiomas (Tabela 7) reflete o gerador de dados e não deve ser lida como achado pedagógico.'),

  H2('4.6 Índices nos dois SGBDs'),
  txt('A Tabela 10 mostra a mediana de 7 execuções de EXPLAIN ANALYZE nos três estágios (arquivo evidencias/comparacao/resultados.json; planos completos em planos_postgres.txt e planos_mysql.txt). No estágio “índices” criamos idx_matricula_turma_sit (id_turma, situacao) e idx_turma_semestre (semestre) nos dois SGBDs.'),
  cap('Tabela 10. Mediana do tempo de execução (ms) por estágio de indexação', true),
  table(['Consulta', 'PG sem índice', 'PG esquema', 'PG índices', 'MySQL sem índice', 'MySQL esquema', 'MySQL índices'],
    [['Q1 matrículas do aluno 12345', 'Q1'], ['Q2 avaliações da matrícula 150000', 'Q2'], ['Q3 turmas de 2026.1', 'Q3'], ['Q4 ativas da turma 11', 'Q4']].map(([n, q]) => [n,
      f(ms(q, 'pg', 'S0_sem_indice')), f(ms(q, 'pg', 'S1_esquema')), f(ms(q, 'pg', 'S2_indices')),
      f(ms(q, 'mysql', 'S0_sem_indice')), f(ms(q, 'mysql', 'S1_esquema')), f(ms(q, 'mysql', 'S2_indices'))]),
    [2204, 1050, 1050, 1050, 1050, 1050, 1050], { right: [1, 2, 3, 4, 5, 6], size: 16 }),
  spacer(),
  img(`${R}/docs/indices.png`, 470, 241),
  cap('Figura 2. Mediana do tempo das consultas Q1 a Q4 sem e com índices (escala logarítmica)'),
  txt(`Sem índice, as quatro consultas fazem varredura completa nos dois SGBDs, e o MySQL foi ${x(ms('Q1', 'mysql', 'S0_sem_indice'), ms('Q1', 'pg', 'S0_sem_indice'))}, ${x(ms('Q2', 'mysql', 'S0_sem_indice'), ms('Q2', 'pg', 'S0_sem_indice'))} e ${x(ms('Q4', 'mysql', 'S0_sem_indice'), ms('Q4', 'pg', 'S0_sem_indice'))} vezes mais lento que o PostgreSQL em Q1, Q2 e Q4. Um fator possível é que o plano do PostgreSQL usou varredura paralela (Parallel Seq Scan), enquanto o do MySQL usou varredura sequencial simples (Table scan). Com índices, Q1, Q2 e Q4 caem para frações de milissegundo nos dois (de ${f(ms('Q1', 'pg', 'S0_sem_indice'))} para ${f(ms('Q1', 'pg', 'S2_indices'))} ms em Q1 no PostgreSQL e de ${f(ms('Q1', 'mysql', 'S0_sem_indice'))} para ${f(ms('Q1', 'mysql', 'S2_indices'))} ms no MySQL). Os valores acima de 100 ms no MySQL são exibidos pelo próprio SGBD com três algarismos significativos.`),
  txt(`O estágio “esquema” revela a diferença mais útil para o projeto: em Q4 o MySQL já usa o índice criado automaticamente para a chave estrangeira (${f(ms('Q4', 'mysql', 'S1_esquema'))} ms), enquanto o PostgreSQL, que não indexa chaves estrangeiras, ainda faz varredura completa (${f(ms('Q4', 'pg', 'S1_esquema'))} ms) até receber idx_matricula_turma_sit (${f(ms('Q4', 'pg', 'S2_indices'))} ms). Em Q3, a tabela turma tem apenas 4.560 linhas, e o ganho absoluto é pequeno nos dois SGBDs (de ${f(ms('Q3', 'pg', 'S1_esquema'))} para ${f(ms('Q3', 'pg', 'S2_indices'))} ms no PostgreSQL e de ${f(ms('Q3', 'mysql', 'S1_esquema'))} para ${f(ms('Q3', 'mysql', 'S2_indices'))} ms no MySQL). Q1 e Q2 usam, nos dois, os índices implícitos das restrições UNIQUE, cujas primeiras colunas são id_aluno e id_matricula. Uma tentativa inicial de criar um índice separado em matricula(id_aluno) foi descartada por ser redundante.`),

  H2('4.7 Desempenho das consultas analíticas'),
  txt('A Tabela 11 compara as consultas C1 a C5 (mediana de 7 execuções, estágio com índices) e a Figura 3 as ilustra.'),
  cap('Tabela 11. Mediana do tempo das consultas analíticas (ms)', true),
  table(['Consulta', 'PostgreSQL', 'MySQL', 'Mais rápido'],
    ['C1', 'C2', 'C3', 'C4', 'C5'].map((k, i) => [['C1 boletim', 'C2 ocupação', 'C3 aprovação por idioma', 'C4 alerta pedagógico', 'C5 custo por professor'][i],
      f(K[k].pg.ms), f(K[k].mysql.ms),
      K[k].pg.ms < K[k].mysql.ms ? `PostgreSQL (${x(K[k].mysql.ms, K[k].pg.ms)}x)` : `MySQL (${x(K[k].pg.ms, K[k].mysql.ms)}x)`]),
    [2800, 1800, 1800, 2104], { right: [1, 2] }),
  spacer(),
  img(`${R}/docs/consultas_comparacao.png`, 470, 216),
  cap('Figura 3. Mediana do tempo das consultas C1 a C5 em cada SGBD (escala logarítmica)'),
  txt(`Os planos explicam as diferenças maiores. Em C2 e C4, o PostgreSQL com a configuração padrão escolheu varrer as 302 mil matrículas com junção por hash, enquanto o MySQL usou busca por índice nas 80 turmas de 2026.1 (${f(K.C2.pg.ms)} contra ${f(K.C2.mysql.ms)} ms em C2). Para saber se o plano do PostgreSQL era mesmo pior, repetimos as consultas com enable_seqscan e enable_hashjoin desativados (evidencias/comparacao/controle_planner_pg.txt): C2 caiu para 1,79 ms e C4 para 6,50 ms. Com o ajuste de configuração mais comum, random_page_cost = 1,1, o planejador passou a escolher o plano com índice sozinho: C2 ficou em 1,49 ms e C4 em 12,3 ms, enquanto C3 permaneceu em cerca de 1.020 ms. Em C3, o plano do PostgreSQL usa junção por intercalação (merge join) com agregação sobre dados ordenados, e o do MySQL materializa uma tabela temporária após cerca de 300 mil buscas por índice em avaliacao (que devolvem 904 mil linhas), o que é compatível com a diferença de ${x(K.C3.mysql.ms, K.C3.pg.ms)} vezes a favor do PostgreSQL. Nas consultas pequenas (C1 e C5), a diferença é de décimos de milissegundo.`),

  H2('4.8 Comparação geral'),
  cap('Tabela 12. Síntese da comparação entre PostgreSQL e MySQL neste experimento', true),
  table(['Aspecto', 'PostgreSQL 16.15', 'MySQL 8.0.46'], [
    ['Carga completa (scripts 02 e 03)', '18,0 s', '26,0 s (execução única)'],
    ['Tamanho de matricula (dados + índices)', '35 MB (17 MB de índices)', '30,5 MB (17,0 MB de índices)'],
    ['Tamanho de avaliacao (dados + índices)', '96 MB (47 MB de índices)', '53,1 MB (17,5 MB de índices)'],
    ['CHECK / FK / PK / UNIQUE', '12 / 7 / 7 / 7', '11 / 7 / 7 / 7'],
    ['Gatilhos necessários', '2', '5'],
    ['Violações de regra rejeitadas (T1 a T15)', '15 de 15', '15 de 15'],
    ['Disputa pela última vaga sem trava / com trava', '2 matrículas / 1 matrícula', '2 matrículas / 1 matrícula'],
    ['Índice automático em FK', 'Não', 'Sim'],
    ['Varredura completa (Q1/Q2/Q4, ms)', `${f(ms('Q1', 'pg', 'S0_sem_indice'))} / ${f(ms('Q2', 'pg', 'S0_sem_indice'))} / ${f(ms('Q4', 'pg', 'S0_sem_indice'))}`, `${f(ms('Q1', 'mysql', 'S0_sem_indice'))} / ${f(ms('Q2', 'mysql', 'S0_sem_indice'))} / ${f(ms('Q4', 'mysql', 'S0_sem_indice'))}`],
    ['C2 / C3 / C4 com configuração padrão (ms)', `${f(K.C2.pg.ms)} / ${f(K.C3.pg.ms)} / ${f(K.C4.pg.ms)}`, `${f(K.C2.mysql.ms)} / ${f(K.C3.mysql.ms)} / ${f(K.C4.mysql.ms)}`],
  ], [3300, 2600, 2604]),
  spacer(),
  txt('Para este modelo, a principal vantagem do PostgreSQL na integridade é permitir que a regra de data de nascimento seja uma restrição declarativa e usar menos gatilhos; a do MySQL é indexar chaves estrangeiras automaticamente, o que evita um tipo de lentidão para quem esquece de criar o índice. Em desempenho, nenhum SGBD foi superior em todas as consultas: o resultado dependeu do plano escolhido e, no PostgreSQL, de um parâmetro de configuração.'),
);

// ---------- 5 ----------
add(H1('5. Conclusão'),
  txt('O trabalho projetou um banco de dados para escola de idiomas, implementou-o em PostgreSQL e MySQL e comprovou por execução que as regras que a escola precisa garantir (vagas, habilitação do professor, notas válidas, unicidade de CPF e de matrícula, histórico protegido contra exclusão) são aplicadas pelo próprio SGBD nos dois casos. Dos 18 testes de cada SGBD, as 15 tentativas de violação foram rejeitadas, a cascata e o controle positivo se comportaram como esperado, e a disputa concorrente pela última vaga terminou com uma única matrícula quando o gatilho usa bloqueio de linha; sem o bloqueio, a turma foi superlotada nos dois SGBDs.'),
  txt('A comparação mostrou diferenças práticas que ficam invisíveis em um projeto feito só em um SGBD: o CHECK com CURRENT_DATE não existe no MySQL, a sintaxe de agregação condicional e de inserção idempotente difere, o MySQL cria índice em chaves estrangeiras e o PostgreSQL não, e o PostgreSQL com a configuração padrão escolheu planos ruins em C2 e C4, resolvidos por random_page_cost. Em contrapartida, o PostgreSQL foi muito mais rápido em C3. A escolha entre os dois, para esta aplicação, é mais uma questão de dialeto, de configuração e de conhecimento da equipe do que de capacidade.'),
  txt('As limitações são as seguintes. Os dados são sintéticos, e taxas de aprovação e distribuição de notas não representam uma escola real. Os dois SGBDs rodaram em uma única máquina virtual de 1 vCPU, com configuração padrão e cache pequeno; outras máquinas, versões ou configurações podem inverter as diferenças de desempenho, que devem ser lidas como ordens de grandeza. A execução registrada do MySQL usou o cliente de linha de comando, não a interface gráfica do Workbench. As bases dos dois SGBDs não são idênticas linha a linha. O tempo de carga é de uma única execução. O CHECK de CPF valida o formato, mas não os dígitos verificadores, e o gatilho de vagas considera apenas matrículas ATIVAS. Como trabalhos futuros, sugerimos validar os dígitos do CPF, adicionar presença e mensalidade, testar mais concorrência e repetir a comparação em outra máquina e com ajuste de configuração nos dois SGBDs.'),
  txt('Os scripts, as saídas brutas, o diagrama e o plano ágil estão no repositório do projeto: [inserir URL do repositório GitHub].'),
);

add(H1('Declaração de Uso de Inteligência Artificial'),
  txt('Conforme a Portaria CNPq nº 2.664/2026 e o Art. 12º do Manual de Normas de TCC, declaramos o uso de IA generativa neste trabalho. (i) Ferramenta: Claude (Anthropic), modelo Claude Sonnet 5.5. (ii) Etapas: geração e revisão do código SQL para PostgreSQL e MySQL (esquema, cargas, testes, consultas e índices), portabilidade entre os dois dialetos, execução dos scripts em um ambiente de teste com PostgreSQL 16.15 e MySQL 8.0.46, benchmark comparativo, geração do diagrama e dos gráficos, estruturação do plano ágil e redação deste artigo a partir das saídas obtidas. (iii) Finalidade: acelerar a implementação e a documentação. Os valores das tabelas foram extraídos automaticamente dos arquivos de saída em evidencias/. O grupo [deve confirmar aqui que reexecutou os scripts em sua própria máquina (inclusive no MySQL Workbench), revisou cada decisão e se responsabiliza pelo conteúdo; ajuste este parágrafo conforme o que de fato ocorreu].'),
);

const refs = [
  '[1] CODD, E. F. A relational model of data for large shared data banks. Communications of the ACM, v. 13, n. 6, p. 377–387, 1970.',
  '[2] ELMASRI, R.; NAVATHE, S. B. Sistemas de Banco de Dados. 7. ed. São Paulo: Pearson, 2018.',
  '[3] SILBERSCHATZ, A.; KORTH, H. F.; SUDARSHAN, S. Database System Concepts. 7. ed. New York: McGraw-Hill, 2019.',
  '[4] THE POSTGRESQL GLOBAL DEVELOPMENT GROUP. PostgreSQL 16 Documentation. Disponível em: https://www.postgresql.org/docs/16/. Acesso em: nov. 2026.',
  '[5] ORACLE CORPORATION. MySQL 8.0 Reference Manual. Disponível em: https://dev.mysql.com/doc/refman/8.0/en/. Acesso em: nov. 2026.',
  '[6] ORACLE CORPORATION. MySQL Workbench Manual. Disponível em: https://dev.mysql.com/doc/workbench/en/. Acesso em: nov. 2026.',
  '[7] COUNCIL OF EUROPE. Common European Framework of Reference for Languages: Learning, Teaching, Assessment. Cambridge: Cambridge University Press, 2001.',
  '[8] BECK, K. et al. Manifesto for Agile Software Development. 2001. Disponível em: https://agilemanifesto.org. Acesso em: nov. 2026.',
];
add(H1('Referências'), ...refs.map(r => new Paragraph({ alignment: AlignmentType.JUSTIFIED, spacing: { after: 80 }, indent: { left: 567, hanging: 567 }, children: [run(r, { size: 22 })] })));

const doc = new Document({
  creator: 'Grupo', title: 'Banco de Dados para uma Escola de Idiomas: PostgreSQL e MySQL',
  styles: { default: { document: { run: { font: TNR, size: 24 } } } },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1984, right: 1701, bottom: 1417, left: 1701, header: 708, footer: 708 } } },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], font: TNR, size: 20 })] })] }) },
    children,
  }],
});
const out = process.argv[2] || `${R}/Artigo_Escola_de_Idiomas_PostgreSQL_MySQL.docx`;
Packer.toBuffer(doc).then(b => { fs.writeFileSync(out, b); console.log('ok', out); });
