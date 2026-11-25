/ test_order.q - test the second half of the order analysis
/ (src/analysis/order.q: which columns must be sorted) against Scala.

/ Two golden files, both made by tools/gen_order_golden.sh with the real
/ Scala order analysis (tools/OrderDump.java):

/ order_cols_golden.txt has a block for every case of
/ order_cols_cases.txt, for example
/   === -<TAB>expr<TAB>c1 + c2 + max(c3 + sums(c4), c5)
/   DIRECT<TAB>Id(c4)
/   DIRECTROOT<TAB>Id(c1) Id(c2) Id(c4)
/   GROUP<TAB>Id(c1) Id(c2)
/   GROUP<TAB>Id(c3) Id(c4) Id(c5)
/   SORT<TAB>Id(c3) Id(c4) Id(c5)
/   SORTROOT<TAB>Id(c1) Id(c2) Id(c3) Id(c4) Id(c5)
/   ALLCOLS<TAB>Id(c1) Id(c2) Id(c3) Id(c4) Id(c5)
/ (an exprs case has only the last three lines).

/ order_plans_golden.txt has a block for every program in tests/inputs
/ with a query, and in it a few lines for every query plan:
/   === tests/inputs/edge_cases/x.a
/   PLAN<TAB>1 main
/   HASSORT<TAB>1
/   SORT<TAB>Asc Id(c1), Desc ColumnAccess(t,c2)
/   ABOVE<TAB>Id(c1)
/   ABOVEALL<TAB>Id(c1) Id(c3)
/ (SORT, ABOVE and ABOVEALL only when the plan has a sort).

/ This file computes the same lines with the q parser and order.q and
/ checks that they are identical. The checks at the end are the tests of
/ OrderAnalysisTestSuite.scala that do not start from AQuery text.

/ Run from the aquery-q folder:   bin/l_m64 tests/analysis/test_order.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ readBlocks[path]
/   The blocks of a golden file: a dictionary from each "=== ..." line
/   (a symbol) to the lines after it. (Same as in test_expr.q.)
.colsTest.readBlocks:{[path]
  lines:read0 hsym `$path;
  lines:lines where 0 < count each lines;
  lines:lines where not "#" = first each lines;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;
  (`$first each blocks)!{1 _ x} each blocks};

/ setText[s]
/   A set of columns as the golden files print it: the keys, joined with
/   a space ("" for an empty set).
.colsTest.setText:{[s] " " sv string s};

/ envFor[context]
/   The function table for a case's context (as in test_order_funs.q).
.colsTest.envFor:{[context]
  if[context ~ enlist "-"; :.aqc.order.env ()];
  .aqc.order.env .aqc.gen.parseText "\n" sv read0 hsym `$context};

/ parseAll[rule; text]
/   The expressions of a case: one for expr or predicate, one per
/   ";"-separated part for exprs. `fail if any part does not parse.
.colsTest.parseAll:{[rule;text]
  parts:$[rule = `exprs; ";" vs text; enlist text];
  q:$[rule = `predicate; .aqc.parse.predicate; .aqc.parse.expr];
  out:();
  k:0;
  while[k < count parts;
    r:.aqc.parse.parseRule[q; parts k];
    if[not r`ok; :`fail];
    out:.aqc.ast.append[out; r`node];
    k+:1];
  out};

/ caseLines[context; rule; text]
/   What OrderDump.java (mode cols) prints for one case, from q.
.colsTest.caseLines:{[context;rule;text]
  es:.colsTest.parseAll[rule; text];
  if[`fail ~ es; :enlist "PARSE-FAILURE"];
  env:.colsTest.envFor context;
  out:();
  if[not rule = `exprs;
    e:es 0;
    out,:enlist "DIRECT\t",.colsTest.setText .aqc.order.directCols[env; 0b; e];
    out,:enlist "DIRECTROOT\t",.colsTest.setText .aqc.order.directCols[env; 1b; e];
    out,:{"GROUP\t",.colsTest.setText x} each .aqc.order.interactions[env; e]];
  out,:enlist "SORT\t",.colsTest.setText .aqc.order.colsToSort[env; es; 0b];
  out,:enlist "SORTROOT\t",.colsTest.setText .aqc.order.colsToSort[env; es; 1b];
  out,:enlist "ALLCOLS\t",.colsTest.setText .aqc.order.allColsOf es;
  out};

/ Every case of order_cols_cases.txt.
.colsTest.cases:.colsTest.readBlocks "tests/analysis/order_cols_golden.txt";
.colsTest.headers:key .colsTest.cases;
.colsTest.k:0;
while[.colsTest.k < count .colsTest.headers;
  header:string .colsTest.headers .colsTest.k;
  parts:"\t" vs 4 _ header;          / 4 _ drops "=== "
  text:"\t" sv 2 _ parts;
  .test.checkLines[header; .colsTest.caseLines[parts 0; `$parts 1; text]; .colsTest.cases `$header];
  .colsTest.k+:1];


/ sortText[os]
/   The sort pairs of a plan as the golden files print them:
/   "Asc Id(c1), Desc ColumnAccess(t,c2)"
.colsTest.sortText:{[os]
  pairs:();
  k:0;
  while[k < count os;
    o:os k;
    pairs,:enlist (string o`_1)," ",string .aqc.order.colKey o`_2;
    k+:1];
  ", " sv pairs};

/ exprsAbove[r]
/   The expressions of every node of plan r above its first SortBy, in
/   walk order (what the optimizer's sortToSortCols looks at).
.colsTest.exprsAbove:{[r]
  nodes:.aqc.nodes.takeWhile[{[x] not .aqc.order.isSortBy x}; {[x] x}; r];
  out:();
  k:0;
  while[k < count nodes;
    out:.aqc.ast.concat[out; .aqc.nodes.planExprs nodes k];
    k+:1];
  out};

/ planLines[env; label; r]
/   The lines for one query plan.
.colsTest.planLines:{[env;label;r]
  has:.aqc.order.hasSortBy r;
  out:("PLAN\t",label; "HASSORT\t",$[has; "1"; "0"]);
  if[not has; :out];
  above:.colsTest.exprsAbove r;
  out,:enlist "SORT\t",.colsTest.sortText .aqc.order.getSort r;
  out,:enlist "ABOVE\t",.colsTest.setText .aqc.order.colsToSort[env; above; 1b];
  out,:enlist "ABOVEALL\t",.colsTest.setText .aqc.order.allColsOf above;
  out};

/ queryLines[env; n; q]
/   The lines for every plan of Query node q (statement number n): its
/   WITH tables (Tuple(name, columns, plan)), then the main plan.
.colsTest.queryLines:{[env;n;q]
  out:();
  k:0;
  while[k < count q`local;
    l:(q`local) k;
    out,:.colsTest.planLines[env; (string n)," local ",.aqc.tc.err.str l`_1; l`_3];
    k+:1];
  out,.colsTest.planLines[env; (string n)," main"; q`main]};

/ fileLines[path]
/   The lines for every query plan in a program file.
.colsTest.fileLines:{[path]
  prog:.aqc.gen.parseText "\n" sv read0 hsym `$path;
  env:.aqc.order.env prog;
  out:();
  k:0;
  while[k < count prog;
    s:prog k;
    n:.aqc.nodes.name s;
    if[n = `Query; out,:.colsTest.queryLines[env; k + 1; s]];
    if[n = `Create;
      if[`Right ~ (s`source)`node; out,:.colsTest.queryLines[env; k + 1; (s`source)`value]]];
    k+:1];
  out};

/ Every program in order_plans_golden.txt.
.colsTest.plans:.colsTest.readBlocks "tests/analysis/order_plans_golden.txt";
.colsTest.files:key .colsTest.plans;
.colsTest.k:0;
while[.colsTest.k < count .colsTest.files;
  header:string .colsTest.files .colsTest.k;
  .test.checkLines[header; .colsTest.fileLines 4 _ header; .colsTest.plans `$header];
  .colsTest.k+:1];


/ The OrderAnalysisTestSuite.scala tests that start from sets, not text.

/ ids[names]
/   A set of Id columns from a list of names: ids `c4`c5 is Id(c4) Id(c5).
.colsTest.ids:{[names] asc `$"Id(",/:(string names),\:")"};
/ col[t; c]
/   The key of t.c.
.colsTest.col:{[t;c] `$"ColumnAccess(",(string t),",",(string c),")"};

/ test "interactions indirectly reachable"
.test.check["indirect 1";
  .aqc.order.indirect[(.colsTest.ids `c4`c5`c7; .colsTest.ids `c6`c7); .colsTest.ids enlist `c5];
  .colsTest.ids `c4`c6`c7];
.colsTest.groups2:(.colsTest.ids `c4`c5; .colsTest.ids `c5`c6; .colsTest.ids enlist `c6; .colsTest.ids enlist `c7);
.test.check["indirect 2"; .aqc.order.indirect[.colsTest.groups2; .colsTest.ids enlist `c7]; `symbol$()];
.test.check["indirect 3"; .aqc.order.indirect[.colsTest.groups2; .colsTest.ids enlist `c6]; .colsTest.ids `c4`c5];
.test.check["indirect 4: c5 and t.c5 are the same";
  .aqc.order.indirect[(.colsTest.ids `c4`c5; asc (.colsTest.col[`t;`c5]; first .colsTest.ids enlist `c6); .colsTest.ids enlist `c6; .colsTest.ids enlist `c7); .colsTest.ids enlist `c6];
  asc (.colsTest.col[`t;`c5]),.colsTest.ids `c4`c5];
.test.check["indirect 5: t1.c5 and t.c5 are not";
  .aqc.order.indirect[(asc (first .colsTest.ids enlist `c4; .colsTest.col[`t1;`c5]); asc (.colsTest.col[`t;`c5]; first .colsTest.ids enlist `c6); .colsTest.ids enlist `c6; .colsTest.ids enlist `c7); .colsTest.ids enlist `c6];
  enlist .colsTest.col[`t;`c5]];

/ test "has sort and extract sort"
.colsTest.plan:{[text] ((.aqc.gen.parseText text) 0)`main};
.colsTest.q1:.colsTest.plan "SELECT * FROM t ASSUMING ASC c1, DESC t.c2 WHERE c1 > 2";
.test.check["query 1 has a sort"; .aqc.order.hasSortBy .colsTest.q1; 1b];
.test.check["query 1 sort"; .colsTest.sortText .aqc.order.getSort .colsTest.q1; "Asc Id(c1), Desc ColumnAccess(t,c2)"];
.colsTest.q2:.colsTest.plan "SELECT * FROM t WHERE c1 > 2";
.test.check["query 2 has no sort"; .aqc.order.hasSortBy .colsTest.q2; 0b];
.test.check["query 2 sort is empty"; count .aqc.order.getSort .colsTest.q2; 0];
.colsTest.q3:.colsTest.plan "SELECT * FROM t, t1 INNER JOIN t2 USING c1 ASSUMING ASC c1, DESC t.c2 WHERE c1 > 2";
.test.check["query 3 sort"; .colsTest.sortText .aqc.order.getSort .colsTest.q3; "Asc Id(c1), Desc ColumnAccess(t,c2)"];

/ isPrefixSort (used by the optimizer; Scala tests it only through it)
.colsTest.os:{[text] .aqc.order.getSort .colsTest.plan "SELECT * FROM t ASSUMING ",text};
.colsTest.sameKey:{[a;b] (.aqc.order.colKey a) ~ .aqc.order.colKey b};
.test.check["ASC c1 is a prefix of ASC c1, DESC c2";
  .aqc.order.isPrefixSort[.colsTest.os "ASC c1"; .colsTest.os "ASC c1, DESC c2"; .colsTest.sameKey]; 1b];
.test.check["a sort is a prefix of itself";
  .aqc.order.isPrefixSort[.colsTest.os "ASC c1, DESC c2"; .colsTest.os "ASC c1, DESC c2"; .colsTest.sameKey]; 1b];
.test.check["ASC c1 is not a prefix of DESC c1";
  .aqc.order.isPrefixSort[.colsTest.os "ASC c1"; .colsTest.os "DESC c1"; .colsTest.sameKey]; 0b];
.test.check["a longer sort is not a prefix";
  .aqc.order.isPrefixSort[.colsTest.os "ASC c1, DESC c2"; .colsTest.os "ASC c1"; .colsTest.sameKey]; 0b];
.test.check["ASC c1 is not a prefix of ASC t.c1 with exact columns";
  .aqc.order.isPrefixSort[.colsTest.os "ASC c1"; .colsTest.os "ASC t.c1"; .colsTest.sameKey]; 0b];

/ keys and nodes
.test.check["keyNode gives back the column";
  .aqc.order.colKey .aqc.order.keyNode `$"ColumnAccess(t,c1)"; `$"ColumnAccess(t,c1)"];
.test.check["keyNode of an Id"; .aqc.order.colKey .aqc.order.keyNode `$"Id(c1)"; `$"Id(c1)"];

.test.finish[];
