/ test_run.q - run AQuery programs in L with .aqc.run and check the
/ results (version 5, milestone 1).

/ Until version 4 every test compared text (tokens, trees, q code). These
/ tests check what the q code does: each one builds small tables in q,
/ runs an AQuery program on them, and compares the result with a table
/ written by hand.

/ Run from the aquery-q folder:   bin/l_m64 tests/runtime/test_run.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ 1. base_l.q is base.q with the "cols" parameter renamed (lines 201 and
/    202, see src/runtime/README.md) and nothing else changed.
orig:read0 `:src/runtime/base.q;
copy:read0 `:src/runtime/base_l.q;
.test.check["base_l.q has as many lines as base.q"; count copy; count orig];
n:min (count orig; count copy);
changed:where not (n # orig) ~' n # copy;     / ~' compares line by line
.test.check["base_l.q differs from base.q only on lines 201 and 202"; 1 + changed; 201 202];
.test.check["base_l.q line 201"; copy 200; ".trg.kdbDeleteColsStmt:{[tbl;cs]"];
.test.check["base_l.q line 202"; copy 201; "  .trg.kfunctional[\"!\"; string tbl; \"\"; \"\"; .trg.symCode cs]"];
.test.check["the runtime is loaded"; all `initQueryState`insert`load`save in key `.aq; 1b];


/ 2. Queries. freshT[] (re)makes the table t that the tests query, so a
/    test that changes t does not affect the next one.
freshT:{[] `t set ([] a:1 2 3; b:10 20 30)};

freshT[];
.test.check["SELECT ... WHERE";
  .aqc.run "SELECT a, b FROM t WHERE a > 1";
  ([] a:2 3; b:20 30)];
.test.check["SELECT *";
  .aqc.run "SELECT * FROM t";
  ([] a:1 2 3; b:10 20 30)];
.test.check["an expression, named with AS";
  .aqc.run "SELECT a + b AS s FROM t";
  ([] s:11 22 33)];

g:([] k:`x`y`x; v:1 2 3);
.test.check["a string constant is compared as a symbol";
  .aqc.run "SELECT v FROM g WHERE k = \"x\"";
  ([] v:1 3)];
.test.check["GROUP BY with sum";
  .aqc.run "SELECT k, sum(v) AS s FROM g GROUP BY k";
  ([] k:`x`y; s:4 2)];
.test.check["GROUP BY ... HAVING";
  .aqc.run "SELECT k, sum(v) AS s FROM g GROUP BY k HAVING sum(v) > 3";
  ([] k:enlist `x; s:enlist 4)];

/ ASSUMING ASC a sorts by a before the SELECT list runs, so the running
/ total sums(b) follows the order of a.
u:([] a:3 1 2; b:30 10 20);
.test.check["ASSUMING ASC with a running sum";
  .aqc.run "SELECT a, sums(b) AS r FROM u ASSUMING ASC a";
  ([] a:1 2 3; r:10 30 60)];

v:([] a:1 2 4; c:`p`q`r);
.test.check["INNER JOIN ... USING";
  .aqc.run "SELECT a, b, c FROM t INNER JOIN v USING a";
  ([] a:1 2; b:10 20; c:`p`q)];


/ 3. Statements that change tables. They change the global tables, so the
/    checks look at the tables afterwards.
.aqc.run "CREATE TABLE s (id INT, p INT)";
.test.check["CREATE TABLE makes an empty global table";
  s; ([] id:"j"$(); p:"j"$())];
.aqc.run "INSERT INTO s VALUES(1, 10)\nINSERT INTO s VALUES(2, 20)\nINSERT INTO s VALUES(1, 5)";
.test.check["INSERT ... VALUES adds rows";
  s; ([] id:1 2 1; p:10 20 5)];
.test.check["several statements: the result is the last one's";
  .aqc.run "INSERT INTO s VALUES(3, 1)\nSELECT id, sum(p) AS tot FROM s GROUP BY id";
  ([] id:1 2 3; tot:15 20 1)];

freshT[];
.aqc.run "UPDATE t SET b = b + 1 WHERE a > 1";
.test.check["UPDATE ... WHERE"; t; ([] a:1 2 3; b:10 21 31)];

freshT[];
.aqc.run "DELETE FROM t WHERE a = 1";
.test.check["DELETE rows"; t; ([] a:2 3; b:20 30)];

freshT[];
.aqc.run "DELETE b FROM t";
.test.check["DELETE a column"; t; ([] a:1 2 3)];


/ 4. A FUNCTION becomes a global q function that later queries can call.
freshT[];
.test.check["FUNCTION, then a query that calls it";
  .aqc.run "FUNCTION dbl(x) { x * 2 }\nSELECT dbl(b) AS d FROM t";
  ([] d:20 40 60)];
.test.check["the FUNCTION is an ordinary q function"; dbl 5; 10];


/ 5. Code written in q inside <q> ... </q> runs as it is, with script
/    rules: each line that starts in the first column is a new statement,
/    even without a ";".
.aqc.run "<q> vq:42 </q>";
.test.check["<q> verbatim code </q>"; vq; 42];
.aqc.run "<q>\nvq1:1\nvq2:vq1+1\nvqf:{[x]\n  x*10}\n</q>";
.test.check["<q> block of several lines without ;"; (vq1; vq2; vqf 3); 1 2 30];

.test.check["scriptStatements: a function over several lines, a comment, an empty line";
  .aqc.rt.scriptStatements "f:{\n x+1\n };\n// note\n\nf 2";
  ("f:{\n x+1\n };"; "f 2")];
.test.check["scriptStatements: a one-character statement stays a string";
  .aqc.rt.scriptStatements "x"; enlist enlist "x"];
.test.check["scriptStatements: nothing but comments"; .aqc.rt.scriptStatements "// a\n/ b"; ()];


/ 6. SAVE and LOAD through a CSV file in /tmp.
freshT[];
csvPath:"/tmp/aqc_test_run.csv";
.aqc.run "SELECT a, b FROM t INTO OUTFILE \"",csvPath,"\" FIELDS TERMINATED BY \",\"";
.test.check["INTO OUTFILE writes a CSV file";
  read0 hsym `$csvPath; ("a,b";"1,10";"2,20";"3,30")];
.aqc.run "CREATE TABLE w (a INT, b INT)\nLOAD DATA INFILE \"",csvPath,"\" INTO TABLE w FIELDS TERMINATED BY \",\"";
.test.check["LOAD DATA INFILE reads it back"; w; ([] a:1 2 3; b:10 20 30)];


/ 7. runFile, lastCode, running twice, errors.
freshT[];
aPath:"/tmp/aqc_test_run.a";
(hsym `$aPath) 0: ("SELECT a"; "FROM t"; "WHERE b > 15");
.test.check["runFile"; .aqc.runFile aPath; ([] a:2 3)];

query:"SELECT a FROM t WHERE a > 1";
.aqc.run query;
.test.check["lastCode is the q code of the last run"; .aqc.lastCode; .aqc.compile query];
.test.check["running the same query again gives the same result";
  .aqc.run query; .aqc.run query];

/ @[f; x; handler] calls f[x], and on an error calls handler with the
/ error message instead (q's "trap").
.test.check["a parse error is signalled with its position";
  @[.aqc.run; "SELECT FROM t"; {[msg] msg}];
  "parse error at 1:8: identifier expected"];
.test.check["a q error while running is signalled";
  @[.aqc.run; "SELECT a FROM noSuchTable"; {[msg] `failed}];
  `failed];
.test.check["empty text returns nothing"; .aqc.run ""; ::];
.test.check["only blanks returns nothing"; .aqc.run " \n "; ::];

/ 8. Helpers of the \aq console (src/runtime/console.q); the console
/    itself is tested by typing into L, in tests/runtime/test_console.sh.
.test.check["isAq: a query"; .aqc.console.isAq "\\aq SELECT a FROM t"; 1b];
.test.check["isAq: \\aq alone"; .aqc.console.isAq "\\aq"; 1b];
.test.check["isAq: q code"; .aqc.console.isAq "aq:1"; 0b];
.test.check["isAq: another command"; .aqc.console.isAq "\\aqx"; 0b];
.test.check["isAssignment: a:5"; .aqc.console.isAssignment "a:5"; 1b];
.test.check["isAssignment: a+:1"; .aqc.console.isAssignment "a+:1"; 1b];
.test.check["isAssignment: a[0]:1"; .aqc.console.isAssignment "a[0]:1"; 1b];
.test.check["isAssignment: count s is not"; .aqc.console.isAssignment "count s"; 0b];
.test.check["isAssignment: b:1;2 is not"; .aqc.console.isAssignment "b:1;2"; 0b];
.test.check["isAssignment: g[1;2] is not"; .aqc.console.isAssignment "g[1;2]"; 0b];
.test.check["isAssignment: 1+1 is not"; .aqc.console.isAssignment "1+1"; 0b];
.test.check["isAssignment: a line that does not parse"; .aqc.console.isAssignment "1+"; 0b];

.test.finish[];
