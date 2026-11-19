/ test_expr.q - test the expression checker (src/analysis/typecheck.q and
/ errors.q) against Scala.

/ Every case in tests/analysis/expr_cases.txt names a grammar rule (expr or
/ predicate) and a piece of AQuery text. tools/gen_type_golden.sh checked
/ each one with the real Scala type checker (tools/TypeDump.java) and saved
/ the result in tests/analysis/expr_golden.txt:
/   === expr<TAB>2 * 3 / "a"
/   TYPE<TAB>numeric
/   ERROR<TAB>Type Error: expected numeric found string at [1,9]
/ This file does the same with the q parser and the q checker and checks
/ that the lines are identical. Where q deliberately differs from Scala,
/ tests/analysis/divergences.txt gives the expected lines instead.
/ The checks at the end are the "expressions" and "udf" tests of
/ tests/scala/TypeCheckerTestSuite.scala.

/ Run from the aquery-q folder:   bin/l_m64 tests/analysis/test_expr.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The q rule for each rule name used in expr_cases.txt.
.exprTest.rules:`expr`predicate!(.aqc.parse.expr; .aqc.parse.predicate);

/ readBlocks[path]
/   The blocks of a golden-style file: a dictionary from each "=== ..."
/   line (as a symbol, so that it can be looked up) to the lines after it,
/   up to the next "===" line. Blank lines and "#" comment lines are
/   dropped first.
.exprTest.readBlocks:{[path]
  lines:read0 hsym `$path;
  lines:lines where 0 < count each lines;
  lines:lines where not "#" = first each lines;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;        / cut splits lines at each start index
  (`$first each blocks)!{1 _ x} each blocks};   / 1 _ drops the "===" line

/ resultLines[rule; text]
/   What TypeDump.java would print for this case, from the q checker.
.exprTest.resultLines:{[rule;text]
  r:.aqc.parse.parseRule[.exprTest.rules rule; text];
  if[not r`ok; :enlist "PARSE-FAILURE"];
  e:r`node;
  checked:.aqc.tc.expr[.aqc.fn.env (); e];
  out:enlist "TYPE\t",string checked`tag;
  out,:{"ERROR\t",.aqc.tc.err.message x} each checked`errors;
  out,:{"PROHIBITED\t",.aqc.tc.err.message x} each .aqc.tc.prohibited e;
  out};

.exprTest.golden:.exprTest.readBlocks "tests/analysis/expr_golden.txt";
.exprTest.divergent:.exprTest.readBlocks "tests/analysis/divergences.txt";
.exprTest.expected:.exprTest.golden,.exprTest.divergent;   / divergences win

.exprTest.headers:key .exprTest.golden;
.exprTest.k:0;
while[.exprTest.k < count .exprTest.headers;
  header:string .exprTest.headers .exprTest.k;
  parts:"\t" vs 4 _ header;      / 4 _ drops "=== "
  rule:`$parts 0;
  text:"\t" sv 1 _ parts;
  .test.checkLines[header; .exprTest.resultLines[rule; text]; .exprTest.expected `$header];
  .exprTest.k+:1];


/ The "expressions" test of TypeCheckerTestSuite.scala.

/ check[text]
/   The q checker's result for an expression, with only built-ins known.
.exprTest.check:{[text]
  .aqc.tc.expr[.aqc.fn.env (); .aqc.parse.parseRule[.aqc.parse.expr; text]`node]};

/ noErrors[r]  and  someErrors[r]
.exprTest.noErrors:{[r] 0 = count r`errors};
.exprTest.someErrors:{[r] 0 < count r`errors};

.test.check["cannot divide by string"; .exprTest.someErrors .exprTest.check "2 * 3 / \"a\""; 1b];
r:.exprTest.check "x ^ true";
.test.check["can exponentiate with boolean"; (r`tag; .exprTest.noErrors r); (`numeric; 1b)];
r:.exprTest.check "x + y / z";
.test.check["can always handle unknowns"; (r`tag; .exprTest.noErrors r); (`numeric; 1b)];
r:.exprTest.check "-x";
.test.check["negation"; (r`tag; .exprTest.noErrors r); (`numeric; 1b)];
r:.exprTest.check "-false";
.test.check["bad input but assumes type on exit"; (r`tag; count r`errors); (`numeric; 1)];
r:.exprTest.check "CASE f(c1) WHEN TRUE THEN 1 ELSE 2 END";
.test.check["branches agree"; (r`tag; .exprTest.noErrors r); (`numeric; 1b)];
.test.check["branches disagree";
  .exprTest.someErrors .exprTest.check "CASE f(c1) WHEN TRUE THEN 1 ELSE TRUE END"; 1b];
.test.check["branches disagree in nested case";
  .exprTest.someErrors .exprTest.check "CASE f(c1) WHEN TRUE THEN CASE WHEN c1 > 2 THEN 1 ELSE 2 END ELSE TRUE END"; 1b];
.test.check["bad type in when case";
  .exprTest.someErrors .exprTest.check "CASE max(c2) * 1 WHEN \"a\" THEN 1 END"; 1b];
r:.exprTest.check "fills(max(c1) * 1)";
.test.check["fill on numeric -> numeric"; (r`tag; .exprTest.noErrors r); (`numeric; 1b)];
.test.check["tried filling with wrong type";
  .exprTest.someErrors .exprTest.check "fills(\"true\", avgs(c1))"; 1b];
.test.check["wrong number of args"; .exprTest.someErrors .exprTest.check "sums(2, 3, c2)"; 1b];


/ The UDF-call part of the "udf" test (the UDF-body part is in version 6
/ milestone 3, with the statements).
.exprTest.udfEnv:.aqc.fn.env .aqc.gen.parseText "FUNCTION f(x, y) {2}\nFUNCTION g(x) {2}\nFUNCTION h() {2}";
.exprTest.udfErrors:{[text]
  count (.aqc.tc.expr[.exprTest.udfEnv; .aqc.parse.parseRule[.aqc.parse.expr; text]`node])`errors};
.test.check["all good calls work"; .exprTest.udfErrors each ("f(1, 2)"; "g(1)"; "h()"); 0 0 0];
.test.check["all bad calls fail"; 0 < .exprTest.udfErrors each ("f(1, 2, 3)"; "g()"; "h(1)"); 111b];

.test.finish[];
