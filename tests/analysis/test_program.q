/ test_program.q - test the query and statement checks (the second half
/ of src/analysis/typecheck.q) against Scala, on whole programs.

/ tools/gen_program_golden.sh checked every input that parses (the files
/ tests/inputs/<path>.a) with the real Scala type checker
/ (tools/TypeDump.java, mode program) and saved its errors, sorted by
/ position, in tests/analysis/golden/<path>.tc:
/   ERROR<TAB>Type Error: expected boolean found numeric at [1,23]
/ A statement Scala crashes on adds a line CRASH<TAB><statement kind>
/ instead (LOAD, SAVE, CREATE TRIGGER, DROP TRIGGER). The same was done
/ for the hand-written tests/analysis/stmt_cases.a (golden: stmt_cases.tc).
/ This file checks the same programs with the q checker and compares the
/ ERROR lines. Where q deliberately differs (crashing statements),
/ tests/analysis/divergences.txt gives the expected lines instead, in a
/ block "=== program<TAB><input path>".
/ The checks at the end are the "udf", "queries", "modification queries"
/ and program tests of tests/scala/TypeCheckerTestSuite.scala.

/ Run from the aquery-q folder:   bin/l_m64 tests/analysis/test_program.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ readBlocks[path]
/   The blocks of divergences.txt: a dictionary from each "=== ..." line
/   (a symbol) to the lines after it. (Same as in test_expr.q.)
.progTest.readBlocks:{[path]
  lines:read0 hsym `$path;
  lines:lines where 0 < count each lines;
  lines:lines where not "#" = first each lines;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;
  (`$first each blocks)!{1 _ x} each blocks};

.progTest.divergent:.progTest.readBlocks "tests/analysis/divergences.txt";

/ actualLines[input]
/   The q checker's errors for an input file, as golden lines.
.progTest.actualLines:{[input]
  {"ERROR\t",x} each .aqc.tc.messages "\n" sv read0 hsym `$input};

/ expectedLines[input; golden]
/   The expected lines: the divergence block for input if there is one,
/   otherwise the golden file without its CRASH lines.
.progTest.expectedLines:{[input;golden]
  header:`$"=== program\t",input;
  if[header in key .progTest.divergent; :.progTest.divergent header];
  lines:read0 hsym `$golden;
  lines where not {"CRASH\t" ~ 6#x} each lines};

/ checkFile[input; golden]
.progTest.checkFile:{[input;golden]
  .test.checkLines[input; .progTest.actualLines input; .progTest.expectedLines[input; golden]]};

/ Every corpus input that parses.
.progTest.goldens:.test.findFiles["tests/analysis/golden"; ".tc"];
.progTest.k:0;
while[.progTest.k < count .progTest.goldens;
  golden:.progTest.goldens .progTest.k;
  .progTest.checkFile[.test.inputFor["tests/analysis/golden"; golden]; golden];
  .progTest.k+:1];

/ The hand-written statement cases.
.progTest.checkFile["tests/analysis/stmt_cases.a"; "tests/analysis/stmt_cases.tc"];
.progTest.checkFile["tests/analysis/stmt_crash_cases.a"; "tests/analysis/stmt_crash_cases.tc"];


/ The checks of TypeCheckerTestSuite.scala that need statements.

/ errorCount[text]
/   How many errors the q checker finds in AQuery text.
.progTest.errorCount:{[text] count .aqc.tc.messages text};

/ "udf": UDF bodies.
.test.check["bad use of maxs in body";
  0 < .progTest.errorCount "FUNCTION f(x, y) { maxs(\"a\") }"; 1b];
.test.check["body ok"; .progTest.errorCount "FUNCTION f(x, y) { x * y + 2 }"; 0];

/ "queries"
.test.check["bad numeric filter";
  0 < .progTest.errorCount "SELECT * FROM t where c2 > 3 AND maxs(c1) * 2"; 1b];
.test.check["bad numeric having";
  0 < .progTest.errorCount "SELECT sum(c2) FROM t GROUP BY c3 HAVING sums(c4)"; 1b];
/ a join with an ON condition: the parser has no syntax for it, so the
/ node is built by hand, as in the Scala test
.progTest.badJoin:.aqc.ast.join[`InnerJoinOn; .aqc.ast.table["c1"; `None]; .aqc.ast.table["c2"; `None];
  .aqc.nodes.one .aqc.parse.parseRule[.aqc.parse.expr; "avg(c1)"]`node];
.test.check["bad numeric join condition";
  0 < count .aqc.tc.relAlg[.aqc.fn.env (); .progTest.badJoin; `symbol$()]; 1b];
.test.check["type error in projection";
  0 < .progTest.errorCount "SELECT c1 * 2 /\"a\" as bad FROM t WHERE c1 = 2"; 1b];
.test.check["bad local query";
  0 < .progTest.errorCount "WITH\n t1 AS (SELECT * FROM t WHERE avg(c1))\n SELECT * FROM t1"; 1b];
.test.check["duplicate tables";
  0 < .progTest.errorCount "SELECT * FROM t1, t2 INNER JOIN t1 USING c1"; 1b];
.test.check["duplicate alias";
  0 < .progTest.errorCount "SELECT * FROM t1, t2 bad, t3 as bad"; 1b];
.test.check["ok tables";
  .progTest.errorCount "SELECT * FROM t1 as firstT1, t2 INNER JOIN t2 other_t2 USING cx"; 0];
.test.check["bad col access";
  .progTest.errorCount "SELECT bad.c1, some_t.c2 * st.ok, f(c3 * 2) FROM some_t st"; 2];
.test.check["ambig col access";
  0 < .progTest.errorCount "SELECT t.c1 * t.c2 FROM t as first_t, t second_t"; 1b];
.test.check["ambig col access 2";
  0 < .progTest.errorCount "SELECT t.c1 FROM t first_t WHERE c1 > 2"; 1b];
.test.check["non-ambig col access";
  .progTest.errorCount "SELECT first_t.c1 * second_t.c2 FROM t as first_t, t second_t"; 0];
.test.check["bad sorting spec";
  0 < .progTest.errorCount "SELECT * FROM t ASSUMING ASC c2 * 2"; 1b];
.test.check["ok sort";
  .progTest.errorCount "SELECT * FROM t ASSUMING ASC c2, DESC t.c2"; 0];

/ "modification queries"
.test.check["bad col access in update";
  0 < .progTest.errorCount "UPDATE t SET c1 = bad.c2 * 3 WHERE c1 > 2"; 1b];
.test.check["ok update";
  .progTest.errorCount "UPDATE t SET c1 = f(t.c1) ASSUMING ASC c2 WHERE sums(c1 > 2) > 2"; 0];

/ "simple program", "fintime benchmark", "monetbd benchmark", "pandas benchmark"
.progTest.resource:{[name] "\n" sv read0 hsym `$"tests/inputs/resources/",name};
.test.check["simple.a has no errors"; .progTest.errorCount .progTest.resource "simple.a"; 0];
.test.check["fintime.a has no errors"; .progTest.errorCount .progTest.resource "fintime.a"; 0];
.test.check["monetdb.a has no errors"; .progTest.errorCount .progTest.resource "monetdb.a"; 0];
.test.check["pandas.a has no errors"; .progTest.errorCount .progTest.resource "pandas.a"; 0];

.test.finish[];
