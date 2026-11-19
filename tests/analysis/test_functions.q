/ test_functions.q - test the type tags and the function table
/ (src/analysis/types.q, src/analysis/functions.q) against Scala.

/ tools/gen_sig_golden.sh called every Scala built-in's signature with every
/ list of 0 to 3 argument types (tools/TypeDump.java) and saved the answers
/ in tests/analysis/sig_golden.txt, with each built-in's order flags. This
/ file asks the q table the same questions and checks every answer is the
/ same. A few hand-written checks at the end cover consistent and UDFs,
/ which have no Scala output to compare with.

/ Run from the aquery-q folder:   bin/l_m64 tests/analysis/test_functions.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The golden lines, split at tabs:
/   ("FLAGS"; "SUMS"; "orderDependent=1 remOrderDependence=0 usesAggregate=1")
/   ("SIG"; "SUMS"; "numeric,boolean"; "numeric")
.fnTest.golden:{"\t" vs x} each read0 `:tests/analysis/sig_golden.txt;
.fnTest.flagLines:.fnTest.golden where "FLAGS" ~/: first each .fnTest.golden;
.fnTest.sigLines:.fnTest.golden where "SIG" ~/: first each .fnTest.golden;

/ The built-in names in the golden file, and in the q table.
.fnTest.names:`$.fnTest.flagLines[;1];
.test.check["the same 30 built-ins as Scala";
  asc (0!.aqc.fn.builtins)`name; asc .fnTest.names];

/ argTypes[s]
/   The argument types written in a golden line, as a symbol list:
/     argTypes "numeric,boolean"   is `numeric`boolean
/     argTypes "-"                 is `symbol$()   (no arguments)
/   (enlist "-": a one-character string. "-" alone is a char atom, which
/   never matches the 1-character string s.)
.fnTest.argTypes:{[s] $[(enlist "-") ~ s; `symbol$(); `$"," vs s]};

/ flagText[f]
/   The q row's order flags, written the way TypeDump.java writes them.
.fnTest.flagText:{[f]
  r:.aqc.fn.builtins f;
  bit:{$[x; "1"; "0"]};
  "orderDependent=",(bit r`orderDependent),
    " remOrderDependence=",(bit r`remOrderDependence),
    " usesAggregate=",bit r`usesAggregate};

/ Flags: one check per built-in.
.fnTest.k:0;
while[.fnTest.k < count .fnTest.flagLines;
  line:.fnTest.flagLines .fnTest.k;
  .test.check["flags of ",line 1; .fnTest.flagText `$line 1; line 2];
  .fnTest.k+:1];

/ Signatures: one check per built-in, comparing all 259 answers at once.
/ A line reads "numeric,boolean -> numeric"; on a mismatch checkLines
/ prints the first line that differs.
.fnTest.env:.aqc.fn.env ();
.fnTest.k:0;
while[.fnTest.k < count .fnTest.names;
  f:.fnTest.names .fnTest.k;
  lines:.fnTest.sigLines where (string f) ~/: .fnTest.sigLines[;1];
  expected:{(x 2)," -> ",x 3} each lines;
  actual:{[f;x] (x 2)," -> ",string .aqc.fn.resultType[.fnTest.env; f; .fnTest.argTypes x 2]}[f] each lines;
  .test.checkLines["signature of ",string f; actual; expected];
  .fnTest.k+:1];


/ Hand-written checks.

.test.check["consistent: same tag"; .aqc.tc.consistent[`numeric; .aqc.tc.numAndBool]; 1b];
.test.check["consistent: different tag"; .aqc.tc.consistent[`string; .aqc.tc.num]; 0b];
.test.check["consistent: unknown found"; .aqc.tc.consistent[`unknown; .aqc.tc.num]; 1b];
.test.check["consistent: unknown expected"; .aqc.tc.consistent[`string; enlist `unknown]; 1b];
.test.check["allConsistent: empty"; .aqc.tc.allConsistent[`symbol$(); .aqc.tc.num]; 1b];

/ A program with two UDFs: f takes 1 argument, g takes 2.
.fnTest.prog:.aqc.gen.parseText "FUNCTION f(x) { x + 1 }\nFUNCTION g(a, b) { a * b }\nSELECT f(c) FROM t";
.fnTest.udfEnv:.aqc.fn.env .fnTest.prog;
.test.check["env: built-ins plus 2 UDFs"; count .fnTest.udfEnv; 2 + count .aqc.fn.builtins];
.test.check["env: f is known"; .aqc.fn.known[.fnTest.udfEnv; `f]; 1b];
.test.check["env: h is not known"; .aqc.fn.known[.fnTest.udfEnv; `h]; 0b];
.test.check["env: f with 1 argument"; .aqc.fn.resultType[.fnTest.udfEnv; `f; enlist `numeric]; `unknown];
.test.check["env: f with 2 arguments"; .aqc.fn.resultType[.fnTest.udfEnv; `f; `numeric`numeric]; `bad];
.test.check["env: g with 2 arguments"; .aqc.fn.resultType[.fnTest.udfEnv; `g; `string`string]; `unknown];
.test.check["env: UDF order flags off"; .fnTest.udfEnv[`g]`orderDependent; 0b];
.test.check["env: built-ins unchanged"; .aqc.fn.resultType[.fnTest.udfEnv; `SQRT; enlist `string]; `bad];

/ A later definition with the same name replaces the earlier one.
.fnTest.prog2:.aqc.gen.parseText "FUNCTION f(x) { x }\nFUNCTION f(x, y) { x }";
.fnTest.env2:.aqc.fn.env .fnTest.prog2;
.test.check["env: redefined f takes 2"; .aqc.fn.resultType[.fnTest.env2; `f; `unknown`unknown]; `unknown];
.test.check["env: redefined f, one row"; count .fnTest.env2; 1 + count .aqc.fn.builtins];

.test.finish[];
