/ test_codegen.q - check whole programs compiled with -c against the
/ original compiler.

/ tools/gen_reference_q.sh ran `aquery.jar -a 0 -c` on every input that the
/ jar can parse and saved the translated part (from "// Translation begins
/ here") in tests/reference_q/<path>.q. The jar's full output is
/ src/runtime/base.q followed by that file, so this test compiles the same
/ input with the q compiler and checks every line of base.q + <path>.q.
/ (<path>.opt.q, made with the optimizer, is for version 6.)

/ Statements the q code generator does not handle yet signal
/ "codegen: not supported yet: ..."; their programs are counted as skipped
/ until the milestone that adds them.

/ Run from the aquery-q folder:   bin/l_m64 tests/codegen/test_codegen.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ A few hand-written checks on small programs.
code:{[text] .aqc.compile text};
.test.check["one query";
  code "SELECT a FROM t WHERE a > 1";
  ".aq.q0:{\n .aq.initQueryState[];\n aq__t0:.aq.initTable[t;\"t\";0b];\n aq__t0:?[aq__t0;enlist ((>; {x^.aq.cd x} `a; 1));0b;()];\n aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];\n aq__t0\n };\n.aq.q0[]"];
.test.check["queries are numbered";
  .aqc.gen.lines code "SELECT a FROM t\nSELECT b FROM u";
  (".aq.q0:{";" .aq.initQueryState[];";" aq__t0:.aq.initTable[t;\"t\";0b];";
   " aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];";" aq__t0";" };";".aq.q0[]";"";
   ".aq.q1:{";" .aq.initQueryState[];";" aq__t0:.aq.initTable[u;\"u\";0b];";
   " aq__t0:?[aq__t0;();0b;(enlist[`b]!enlist {x^.aq.cd x} `b)];";" aq__t0";" };";".aq.q1[]")];
.test.check["unnamed columns are c__0, c__1";
  (.aqc.gen.lines code "SELECT a + 1, b, max(c) AS m, d * 2 FROM t") 3;
  " aq__t0:?[aq__t0;();0b;((`c__0);(`b);(`m);(`c__1))!((+; {x^.aq.cd x} `a; 1);{x^.aq.cd x} `b;(.aq.max;{x^.aq.cd x} `c);(*; {x^.aq.cd x} `d; 2))];"];
.test.check["FIXED: u.c is named u.c (the jar says t.c)";
  (.aqc.gen.lines code "SELECT t.a, u.c FROM t, u") 5;
  " aq__t2:?[aq__t2;();0b;((`t.a);(`u.c))!({x^.aq.cd x} `t.a;{x^.aq.cd x} `u.c)];"];
.test.check["lines";
  .aqc.gen.lines "a\n\nb\n"; (enlist "a";"";enlist "b")];
.test.check["lines: one-character line, no final break";
  .aqc.gen.lines "x\ny"; (enlist "x";enlist "y")];

/ One of each statement (milestone 3): tests/codegen/stmt_cases.a,
/ compiled by the jar into tests/codegen/stmt_cases.q (the part after
/ "// Translation begins here") with
/   java -cp aquery.jar edu.nyu.aquery.Aquery -a 0 -c tests/codegen/stmt_cases.a \
/     | sed '1,/^\/\/ Translation begins here$/d' > tests/codegen/stmt_cases.q
/ Helpers for trigger bodies (milestone 4).
.test.check["javaTrim"; .aqc.gen.javaTrim "\n {a}\n "; "{a}"];
.test.check["javaTrim: only blanks"; .aqc.gen.javaTrim " \n "; ""];
.test.check["unwrapBlock"; .aqc.gen.unwrapBlock "{\n a;\n }[];"; "a;"];
.test.check["unwrapBlock: not a block"; .aqc.gen.unwrapBlock " .aq.insert[`t;t;();x]"; " .aq.insert[`t;t;();x]"];
.test.check["injectAfterInit";
  .aqc.gen.injectAfterInit[" .aq.initQueryState[];\n a"; "x:1;"];
  " .aq.initQueryState[];\n x:1;\n a"];
.test.check["injectAfterInit: no marker"; .aqc.gen.injectAfterInit[enlist "a"; "x:1;"]; "x:1;\na"];
.test.check["injectAfterInit: nothing to inject"; .aqc.gen.injectAfterInit["a"; ""]; "a"];
.test.check["refsText"; .aqc.gen.refsText (.aqc.ast.triggerRef[`NewTableRef; "ins"]; .aqc.ast.triggerRef[`OldTableRef; "del"]);
  "\"NEW TABLE AS ins, OLD TABLE AS del\""];
.test.check["refsText: none"; .aqc.gen.refsText (); "()"];
.test.check["endStatement"; .aqc.gen.endStatement ".aq.insert[`t;t;();x]"; ".aq.insert[`t;t;();x];"];
.test.check["endStatement: already ends with ;"; .aqc.gen.endStatement "a:1;"; "a:1;"];

/ FIXED: the statement inside a trigger ends with ";", so it does not run
/ together with the " ctx" line after it. lineBeforeCtx is that line.
lineBeforeCtx:{[text] lines:.aqc.gen.lines code text; lines (lines ? " ctx") - 1};
.test.check["FIXED: ; after INSERT ... SELECT in a trigger";
  lineBeforeCtx "CREATE TRIGGER trg AFTER INSERT ON t REFERENCING NEW TABLE AS ins DO INSERT INTO lg SELECT a FROM ins";
  " .aq.insert[`lg;lg;();aq__insert_src];"];
.test.check["FIXED: ; after INSERT VALUES in a trigger";
  lineBeforeCtx "CREATE TRIGGER trg AFTER INSERT ON t DO INSERT INTO lg VALUES(1)";
  " .aq.insert[`lg;lg;();eval (enlist;1)];"];
.test.check["FIXED: ; after UPDATE in a trigger";
  lineBeforeCtx "CREATE TRIGGER trg AFTER UPDATE ON t DO UPDATE u SET a = 1";
  " .aq.update[`u;aq__t0;();0b;(enlist[{x^.aq.cd x} `a]!enlist 1)];"];

.test.checkLines["statements: tests/codegen/stmt_cases.a";
  .aqc.gen.lines .aqc.compile .aqc.util.readFile "tests/codegen/stmt_cases.a";
  read0 hsym `$"tests/codegen/stmt_cases.q"];


/ The golden files: every tests/reference_q/<path>.q except <path>.opt.q
goldens:.test.findFiles["tests/reference_q"; ".q"];
goldens:goldens where not {".opt.q" ~ -6#x} each goldens;
-1 "golden files: ",string count goldens;
/ leave out the programs whose output differs from the jar on purpose
fixedInputs:.test.skippedInputs "tests/codegen/divergences.txt";
goldens:goldens where not (.test.inputFor["tests/reference_q"] each goldens) in fixedInputs;
-1 "not compared (jar bugs fixed, see tests/codegen/divergences.txt): ",string count fixedInputs;

base:read0 hsym `$"src/runtime/base.q";
skipped:();
i:0;
while[i < count goldens;
  goldenPath:goldens i;
  inputPath:.test.inputFor["tests/reference_q"; goldenPath];
  / @[f; x; handler]: f x, or handler's result if f signals an error
  actual:@[.aqc.gen.compileFile; inputPath; {[err] (`error; err)}];
  $[(0h = type actual) and `error ~ first actual;
    $["codegen: not supported yet" ~ 26#actual 1;
      skipped,:enlist inputPath;
      .test.check[inputPath; actual 1; "no error"]];
    .test.checkLines[inputPath; actual; base,read0 hsym `$goldenPath]];
  i+:1];
-1 "skipped (statements not supported yet): ",string count skipped;

.test.finish[];
