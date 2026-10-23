/ test_rules.q - test single grammar rules against the Scala parser.

/ Every case in tests/parser/rule_cases.txt names a rule and a piece of
/ text. tools/gen_rule_golden.sh ran each case through the real Scala parser
/ and saved the tree it built in tests/parser/rule_golden.txt. This file
/ parses the same text with the q rule and checks the tree is identical,
/ positions included. For a failure only the position is compared (see
/ tests/parser/README.md).

/ Run from the aquery-q folder:   bin/l_m64 tests/parser/test_rules.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The q rule for each Scala rule name used in rule_cases.txt. Most have the
/ same name; from, where, insert, update and delete are q built-ins, so
/ those rules are named differently in parser.q.
.ruleTest.rules:()!();          / an empty dictionary, filled in below
.ruleTest.rules[`query]:.aqc.parse.query;
.ruleTest.rules[`topApply]:.aqc.parse.topApply;
.ruleTest.rules[`fullQuery]:.aqc.parse.fullQuery;
.ruleTest.rules[`localQuery]:.aqc.parse.localQuery;
.ruleTest.rules[`from]:.aqc.parse.fromClause;
.ruleTest.rules[`simpleTable]:.aqc.parse.simpleTable;
.ruleTest.rules[`using]:.aqc.parse.using;
.ruleTest.rules[`where]:.aqc.parse.whereClause;
.ruleTest.rules[`predicate]:.aqc.parse.predicate;
.ruleTest.rules[`order]:.aqc.parse.order;
.ruleTest.rules[`groupBy]:.aqc.parse.groupBy;
.ruleTest.rules[`projection]:.aqc.parse.projection;
.ruleTest.rules[`create]:.aqc.parse.create;
.ruleTest.rules[`schema]:.aqc.parse.schema;
.ruleTest.rules[`insert]:.aqc.parse.insertStmt;
.ruleTest.rules[`update]:.aqc.parse.updateStmt;
.ruleTest.rules[`delete]:.aqc.parse.deleteStmt;
.ruleTest.rules[`trigger]:.aqc.parse.trigger;
.ruleTest.rules[`dropTrigger]:.aqc.parse.dropTrigger;
.ruleTest.rules[`io]:.aqc.parse.io;
.ruleTest.rules[`udf]:.aqc.parse.udf;
.ruleTest.rules[`udfBody]:.aqc.parse.udfBody;
.ruleTest.rules[`verbatim]:.aqc.parse.verbatim;
.ruleTest.rules[`program]:.aqc.parse.program;


/ readCases[path]
/   The cases in a rule_golden.txt file. Each case there starts with a line
/   "=== rule<TAB>text", followed by the expected lines.
/   returns: list of 3-item lists (rule name symbol; text; expected lines)
.ruleTest.readCases:{[path]
  lines:read0 hsym `$path;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;        / cut splits lines at each start index
  cases:();
  k:0;
  while[k < count blocks;
    block:blocks k;
    header:4 _ first block;       / "rule<TAB>text"
    tab:header ? "\t";            / ? finds the first tab
    rule:`$tab # header;
    text:(tab + 1) _ header;
    cases,:enlist (rule;text;1 _ block);
    k+:1];
  cases};


/ actual[rule; text]
/   Parse text with rule and give lines in the golden format: the tree,
/   or one line "FAILURE<TAB>line:col".
.ruleTest.actual:{[rule;text]
  r:.aqc.parse.parseRule[rule;text];
  if[r`ok; :.aqc.ast.format[0;"";r`node]];
  enlist "FAILURE\t",(string r`line),":",string r`col};


cases:.ruleTest.readCases "tests/parser/rule_golden.txt";
-1 "rule cases: ",string count cases;

i:0;
while[i < count cases;
  c:cases i;
  name:(string c 0),": ",c 1;
  .test.checkLines[name;.ruleTest.actual[.ruleTest.rules c 0;c 1];.test.positionOnly c 2];
  i+:1];

.test.finish[];
