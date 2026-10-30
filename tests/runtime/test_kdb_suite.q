/ test_kdb_suite.q - the tests from KdbGeneratorTestSuite.scala that run
/ the generated q code (version 5, milestone 2).

/ Each case is an AQuery program and a q program written by hand that
/ should compute the same thing (see tests/runtime/runner.q). The Scala
/ suite ran every case twice, without and with the optimizer (-a 1); the
/ optimizer comes in version 6, so only the first run is done here.

/ The programs are in tests/runtime/kdb_suite/ (the small cases, copied
/ from the Scala strings, and the q side of the bigger ones) and in
/ tests/inputs/resources/ (the AQuery side of the bigger ones).

/ fintime.a needs the financial data files (about 90 MB, not copied into
/ this folder). They are read from $AQUERY_DATA if it is set, otherwise
/ from the AQueryKDB folder next to this one. Without them the case is
/ skipped.

/ Run from the aquery-q folder:   bin/l_m64 tests/runtime/test_kdb_suite.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q
\l tests/runtime/runner.q

/ The runner's own helper first.
.test.check["noAttributes removes `s#"; attr .runner.noAttributes `s#1 2 3; `];
.test.check["noAttributes on a table";
  attr each value flip .runner.noAttributes ([] a:`s#1 2; b:3 4); ``];

/ fintime.a q0 gives the right rows, but in its name column every cell is
/ a one-item list (,`weekly) where q has the symbol `weekly. The constant
/ "weekly" in a grouped SELECT inside WITH becomes the helper
/ aqConstWeekly:{(count x)#`weekly} (src/parse/rewrite.q), which the
/ query calls once per group, so each group gets a list. Our code is the
/ same as the jar's here (fixing it is left for later).
.runner.knownFailures[`$"fintime.a q0"]:"string constant in a grouped WITH query gives a list per group (same code as the jar)";

dir:"tests/runtime/kdb_suite/";
read:{[file] .runner.readText dir,file};

/ The small cases (KdbGeneratorTestSuite.scala lines 88 to 241 and 395).
.runner.runCase["simple expressions/UDF"; read "simple_expressions.a"; read "simple_expressions.q"; enlist `f];
.runner.runCase["create"; read "create.a"; read "create.q"; `c1`c2];
.runner.runCase["insert"; read "insert.a"; read "insert.q"; enlist `q0];
.runner.runCase["load/save"; read "load_save.a"; read "load_save.q"; enlist `q0];
.runner.runCase["update/delete"; read "update_delete.a"; read "update_delete.q"; `c1`c2];
.runner.runCase["simple queries"; read "simple_queries.a"; read "simple_queries.q"; `c1`c2];

/ The programs from src/test/resources (lines 429 to 480).
inputs:"tests/inputs/resources/";
.runner.runCase["simple.a"; .runner.readText inputs,"simple.a"; read "simple.q"; `$"q",/:string til 10];
.runner.runCase["monetdb.a"; .runner.readText inputs,"monetdb.a"; read "monetdb.q"; `q0`q1];
.runner.runCase["pandas.a"; .runner.readText inputs,"pandas.a"; read "pandas.q"; `$"q",/:string til 7];

/ fintime.a: as in Scala, the AQuery program starts with a <q> block that
/ sets DATAPATH and loads the data (load_fintime.q).
dataDir:$[0 < count getenv `AQUERY_DATA; getenv `AQUERY_DATA; "../AQueryKDB/aquery-master/src/test/resources/data"];
haveData:not () ~ key hsym `$dataDir,"/base.psv";    / key on a missing file is ()
$[haveData;
  [fintime:"<q>\nDATAPATH:\"",dataDir,"\";\n",(read "load_fintime.q"),"\n</q>\n",.runner.readText inputs,"fintime.a";
   .runner.runCase["fintime.a"; fintime; read "fintime.q"; `$"q",/:string til 10]];
  -1 "skipped fintime.a: no data in ",dataDir];

.test.finish[];
