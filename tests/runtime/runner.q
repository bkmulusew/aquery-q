/ runner.q - run an AQuery program and a hand-written q program, and check
/ that they give the same results.

/ A port of the Scala test harness for KdbGeneratorTestSuite.scala: its
/ q/runner.q (copied to tests/runtime/kdb_suite/runner_scala.q) and the
/ Scala functions cleanCode and run. The Scala suite compiled the AQuery
/ program with the jar and started q on both files; here the AQuery
/ program runs with .aqc.run in this L process.

/ In both programs, a test named q0 is a function with no arguments: the
/ AQuery side defines .aq.q0 (every query does, see src/codegen/gen.q),
/ the q side defines .kdb.q0. The test passes when .aq.q0[] ~ .kdb.q0[].

/ Needs aquery.q and tests/lib/testing.q loaded first.


/ cleanCode[text]
/   Scala cleanCode: trim every line, then put one blank in front of every
/   line that does not start with ".". In a q script that makes every line
/   except definitions like ".kdb.q0:{" continue the line before, so q code
/   can be indented freely. Both programs go through it, as in Scala.
/     cleanCode "  .kdb.f:{\n    1}"   is ".kdb.f:{\n 1}"
.runner.cleanCode:{[text]
  trimmed:trim each "\n" vs text;
  indented:{[line] $[line like ".*"; line; " ",line]} each trimmed;
  "\n" sv indented};

/ readText[path]
/   A file's lines joined with "\n" (Scala getCode).
.runner.readText:{[path] "\n" sv read0 hsym `$path};

/ call[name]
/   Call the function with this name (a symbol such as `.aq.q0) with no
/   arguments. An error becomes ("error"; message) instead, so a broken
/   test fails its comparison instead of stopping the whole file.
.runner.call:{[name] @[{[f] (get f)[]}; name; {[msg] ("error"; msg)}]};

/ noAttributes[x]
/   x without q attributes. An attribute is a flag q keeps on a list for
/   speed, such as `s# ("sorted"), which xasc sets on its first sort
/   column. It does not change any value, so two results that differ only
/   in attributes are the same result.
/     noAttributes `s#1 2 3   is 1 2 3
.runner.noAttributes:{[x]
  $[98h = type x; flip .runner.noAttributes each flip x;   / a table: each column
    0h < type x; `#x;                                     / `# removes the attribute
    x]};

/ explain[a; b]
/   For two tables that do not match: print which columns differ, and the
/   first row where each one differs.
.runner.explain:{[a; b]
  if[not (cols a) ~ cols b; :-1 "  columns: ",(.Q.s1 cols a)," vs ",.Q.s1 cols b];
  if[not (count a) = count b; :-1 "  rows: ",(string count a)," vs ",string count b];
  c:0;
  while[c < count cols a;
    name:(cols a) c;
    colA:.runner.noAttributes a name;
    colB:.runner.noAttributes b name;
    if[not colA ~ colB;
      row:first where not colA ~' colB;
      -1 "  column ",(string name),": first difference at row ",(string row),": ",
        (.Q.s1 colA row)," vs ",.Q.s1 colB row];
    c+:1];
  };

/ Tests known to fail, as `$"case test" -> the reason (symbol keys: a
/ string key would make `in` look at its characters one by one). test_kdb_suite.q fills
/ it. Such a test is checked to STILL fail, so that a fix is noticed (then
/ it should be taken off the list).
.runner.knownFailures:()!();

/ compare[label; test]
/   One check: .aq.<test>[] must match .kdb.<test>[] (attributes aside, see
/   noAttributes). On a mismatch the start of both results is printed (they
/   can be tables of 1000 rows).
.runner.compare:{[label; test]
  fromAquery:.runner.call ` sv `.aq,test;     / ` sv `.aq`q0 is `.aq.q0
  fromQ:.runner.call ` sv `.kdb,test;
  ok:(.runner.noAttributes fromAquery) ~ .runner.noAttributes fromQ;
  full:label," ",string test;
  if[(`$full) in key .runner.knownFailures;
    -1 "  known failure: ",full,": ",.runner.knownFailures `$full;
    .test.check[full," (known failure, should still fail)"; ok; 0b];
    :ok];
  if[ok and not fromAquery ~ fromQ;
    -1 "  note: ",label," ",(string test),": same values, different attributes"];
  .test.check[label," ",string test; ok; 1b];
  if[not ok;
    -1 "  AQuery gave: ",300 sublist .Q.s1 fromAquery;
    -1 "  q gave:      ",300 sublist .Q.s1 fromQ;
    if[(98h = type fromAquery) and 98h = type fromQ; .runner.explain[fromAquery; fromQ]]];
  ok};

/ runCase[name; aquery; kdb; tests]
/   Run one test case (Scala run):
/   name:    string shown in the output, e.g. "insert"
/   aquery:  the AQuery program (string)
/   kdb:     the hand-written q program (string), loaded as a script
/   tests:   the test names to compare, e.g. `q0`q1
.runner.runCase:{[name; aquery; kdb; tests]
  -1 "== ",name;
  @[.aqc.run; .runner.cleanCode aquery; {[msg] -1 "  AQuery program failed: ",msg}];
  path:"/tmp/aqc_kdb_suite.q";
  (hsym `$path) 0: enlist .runner.cleanCode kdb;
  @[{[p] system "l ",p}; path; {[msg] -1 "  q program failed: ",msg}];
  .runner.compare[name] each tests;
  };
