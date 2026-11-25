/ test_order_funs.q - test the first half of the order analysis
/ (src/analysis/order.q: function flags, expressions, UDFs) against Scala.

/ Two golden files, both made by tools/gen_order_golden.sh with the real
/ Scala order analysis (tools/OrderDump.java):

/ order_golden.txt has a block for every case of order_cases.txt:
/   === -<TAB>expr<TAB>c1 + max(sums(c2))
/   OD<TAB>1
/   AGG<TAB>1
/ (a udf case also has a REM line, between OD and AGG).

/ order_funs_golden.txt has a block for every program that defines UDFs
/ (tests/inputs, order_udfs.a, order_context.a), one line per UDF:
/   === tests/analysis/order_udfs.a
/   FUN<TAB>later<TAB>orderDependent=1 remOrderDependence=0 usesAggregate=1

/ This file computes the same lines with the q parser and order.q and
/ checks that they are identical.

/ Run from the aquery-q folder:   bin/l_m64 tests/analysis/test_order_funs.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ readBlocks[path]
/   The blocks of a golden file: a dictionary from each "=== ..." line
/   (a symbol) to the lines after it. (Same as in test_expr.q.)
.orderTest.readBlocks:{[path]
  lines:read0 hsym `$path;
  lines:lines where 0 < count each lines;
  lines:lines where not "#" = first each lines;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;
  (`$first each blocks)!{1 _ x} each blocks};

/ bit[b]
/   A boolean as the golden files print it: "1" or "0".
.orderTest.bit:{[b] $[b; "1"; "0"]};

/ envFor[context]
/   The function table for a case's context: "-" means only the
/   built-ins, anything else is the path of a program whose UDFs are known.
.orderTest.envFor:{[context]
  if[context ~ enlist "-"; :.aqc.order.env ()];
  .aqc.order.env .aqc.gen.parseText "\n" sv read0 hsym `$context};

/ The q rule for each rule name used in order_cases.txt.
.orderTest.rules:`expr`predicate`udf!(.aqc.parse.expr; .aqc.parse.predicate; .aqc.parse.udf);

/ caseLines[context; rule; text]
/   What OrderDump.java prints for one case, from the q analysis.
.orderTest.caseLines:{[context;rule;text]
  r:.aqc.parse.parseRule[.orderTest.rules rule; text];
  if[not r`ok; :enlist "PARSE-FAILURE"];
  env:.orderTest.envFor context;
  x:r`node;
  if[rule = `udf;
    :("OD\t",.orderTest.bit .aqc.order.udfHasOrderDependence[env; x];
      "REM\t",.orderTest.bit .aqc.order.udfRemovesOrderDependence[env; x];
      "AGG\t",.orderTest.bit .aqc.order.udfUsesAggregate[env; x])];
  ("OD\t",.orderTest.bit .aqc.order.hasOrderDependence[env; x];
   "AGG\t",.orderTest.bit .aqc.order.usesAggregate[env; x])};

/ Every case of order_cases.txt.
.orderTest.cases:.orderTest.readBlocks "tests/analysis/order_golden.txt";
.orderTest.headers:key .orderTest.cases;
.orderTest.k:0;
while[.orderTest.k < count .orderTest.headers;
  header:string .orderTest.headers .orderTest.k;
  parts:"\t" vs 4 _ header;          / 4 _ drops "=== "
  text:"\t" sv 2 _ parts;            / the text itself may hold a TAB
  .test.checkLines[header; .orderTest.caseLines[parts 0; `$parts 1; text]; .orderTest.cases `$header];
  .orderTest.k+:1];


/ funLines[path]
/   The FUN lines for a program file, from the q analysis: the table is
/   built UDF by UDF, and each UDF's flags are read just after it is
/   added (Scala judges each UDF when it is defined).
.orderTest.funLines:{[path]
  prog:.aqc.gen.parseText "\n" sv read0 hsym `$path;
  env:.aqc.order.env ();
  out:();
  k:0;
  while[k < count prog;
    s:prog k;
    if[`UDF ~ .aqc.nodes.name s;
      env:.aqc.order.addUdf[env; s];
      row:env .aqc.order.sym s`n;
      out,:enlist "FUN\t",(.aqc.tc.err.str s`n),
        "\torderDependent=",(.orderTest.bit row`orderDependent),
        " remOrderDependence=",(.orderTest.bit row`remOrderDependence),
        " usesAggregate=",.orderTest.bit row`usesAggregate];
    k+:1];
  out};

/ Every program in order_funs_golden.txt.
.orderTest.funs:.orderTest.readBlocks "tests/analysis/order_funs_golden.txt";
.orderTest.files:key .orderTest.funs;
.orderTest.k:0;
while[.orderTest.k < count .orderTest.files;
  header:string .orderTest.files .orderTest.k;
  .test.checkLines[header; .orderTest.funLines 4 _ header; .orderTest.funs `$header];
  .orderTest.k+:1];


/ A few checks that read well on their own (the same facts are in the
/ goldens above).
.orderTest.env0:.aqc.order.env ();
.orderTest.expr:{[text] .aqc.parse.parseRule[.aqc.parse.expr; text]`node};
.test.check["SUMS is order-dependent"; .aqc.order.hasOrderDependence[.orderTest.env0; .orderTest.expr "sums(c1)"]; 1b];
.test.check["SUM is not"; .aqc.order.hasOrderDependence[.orderTest.env0; .orderTest.expr "sum(c1)"]; 0b];
.test.check["an unknown function may be"; .aqc.order.hasOrderDependence[.orderTest.env0; .orderTest.expr "til(c1)"]; 1b];
.test.check["c1 + 2 combines no rows"; .aqc.order.usesAggregate[.orderTest.env0; .orderTest.expr "c1 + 2"]; 0b];
.test.check["the built-ins are unchanged"; .aqc.order.env[()] ~ .aqc.fn.builtins; 1b];

.test.finish[];
