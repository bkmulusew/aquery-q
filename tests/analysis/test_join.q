/ test_join.q - test the join analysis (src/analysis/join.q) against Scala.

/ Two golden files, both made by tools/gen_order_golden.sh with the real
/ Scala join analysis (tools/OrderDump.java):

/ join_golden.txt has a block for every case of join_cases.txt, e.g.
/   === place<TAB>t1, t2<TAB>t1.c1 > 1 ; t1.c1 = t2.c1
/   Filter #2<TAB>avail=t1 t2
/     Join Cross<TAB>avail=t1 t2
/       Filter #1<TAB>avail=t1
/         Table t1<TAB>avail=t1
/       Table t2<TAB>avail=t2

/ join_plans_golden.txt has, for every query plan with a join in
/ tests/inputs, the plan with its available tables, then the plan after
/ placing the conditions of each Filter above a join (see the comment at
/ the top of tools/OrderDump.java for the exact format).

/ This file prints the same lines with the q parser and join.q and checks
/ that they are identical, except where tests/analysis/divergences.txt
/ (part 4) says q deliberately prints something else.

/ Run from the aquery-q folder:   bin/l_m64 tests/analysis/test_join.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ readBlocks[path]
/   The blocks of a golden file: a dictionary from each "=== ..." line
/   (a symbol) to the lines after it. (Same as in test_expr.q.)
.joinTest.readBlocks:{[path]
  lines:read0 hsym `$path;
  lines:lines where 0 < count each lines;
  lines:lines where not "#" = first each lines;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;
  (`$first each blocks)!{1 _ x} each blocks};

/ namesText[names]
/   A set of table names as the golden files print it: "t1 t2".
.joinTest.namesText:{[names] " " sv string names};

/ conditionLabels[r; placed]
/   The text after "Filter " for Filter node r: for each of its
/   conditions, #k if it is the k-th condition of placed, else -.
.joinTest.conditionLabels:{[r;placed]
  fs:r`fs;
  labels:();
  k:0;
  while[k < count fs;
    i:0;
    while[(i < count placed) and not (fs k) ~ placed i; i+:1];
    labels,:enlist $[i < count placed; "#",string i + 1; enlist "-"];
    k+:1];
  "," sv labels};

/ nodeText[r; placed]
/   How one plan node is printed (before its available tables).
.joinTest.nodeText:{[r;placed]
  n:.aqc.nodes.name r;
  str:.aqc.tc.err.str;
  if[n = `Table;
    :"Table ",(str r`n),$[`None ~ r`alias; ""; " AS ",str (r`alias)`value]];
  if[n = `Join; :"Join ",string r`jt];
  if[n = `Filter; :"Filter ",.joinTest.conditionLabels[r; placed]];
  string n};

/ treeLines[r; indent; placed]
/   The lines for plan r and everything below it.
.joinTest.treeLines:{[r;indent;placed]
  out:enlist indent,(.joinTest.nodeText[r; placed]),"\tavail=",.joinTest.namesText .aqc.join.getAvail r;
  kids:.aqc.nodes.planChildren r;
  k:0;
  while[k < count kids;
    out,:.joinTest.treeLines[kids k; indent,"  "; placed];
    k+:1];
  out};

/ condition[text]
/   A WHERE condition: the predicate rule first, then expr (what the
/   parser's condition rule tries). `fail if neither parses.
.joinTest.condition:{[text]
  r:.aqc.parse.parseRule[.aqc.parse.predicate; text];
  if[r`ok; :r`node];
  r:.aqc.parse.parseRule[.aqc.parse.expr; text];
  $[r`ok; r`node; `fail]};

/ placeAll[fromPlan; conds]
/   fromPlan with each condition of conds placed, in order. Returns the plan,
/   or the error message (a string) if placeFilter signals one.
/   @[f; x; handler] calls f x, and handler with the message on an error.
.joinTest.placeAll:{[fromPlan;conds]
  acc:fromPlan;
  k:0;
  while[k < count conds;
    acc:@[.aqc.join.placeFilter[acc]; conds k; {[msg] msg}];
    if[10h = type acc; :acc];        / a string: the error message
    k+:1];
  acc};

/ caseLines[rule; parts]
/   What OrderDump.java (mode joincases) prints for one case, from q.
/   parts: the case line split at TABs, without the rule.
.joinTest.caseLines:{[rule;parts]
  if[rule in `expr`predicate;
    q:$[rule = `expr; .aqc.parse.expr; .aqc.parse.predicate];
    r:.aqc.parse.parseRule[q; parts 0];
    if[not r`ok; :enlist "PARSE-FAILURE"];
    used:.aqc.join.tablesUsed r`node;
    :("USED\t",$[.aqc.join.isUnknown used; "unknown"; .joinTest.namesText used];
      "EQSEL\t",$[.aqc.join.isEqualitySelection r`node; "1"; "0"])];
  r:.aqc.parse.parseRule[.aqc.parse.fromClause; parts 0];
  if[not r`ok; :enlist "PARSE-FAILURE"];
  fromPlan:r`node;
  if[rule = `from;
    out:("HASJOIN\t",$[.aqc.join.hasJoin fromPlan; "1"; "0"];
         "AVAIL\t",.joinTest.namesText .aqc.join.tablesAvailable fromPlan);
    :out,.joinTest.treeLines[.aqc.join.annotate fromPlan; ""; ()]];
  / rule place
  texts:";" vs parts 1;
  conds:();
  k:0;
  while[k < count texts;
    c:.joinTest.condition texts k;
    if[`fail ~ c; :enlist "PARSE-FAILURE"];
    conds:.aqc.ast.append[conds; c];
    k+:1];
  placed:.joinTest.placeAll[fromPlan; conds];
  if[10h = type placed; :enlist "ERROR\t",placed];
  .joinTest.treeLines[placed; ""; conds]};

/ Every case of join_cases.txt.
/ Where q deliberately differs from Scala (the two placeFilter fixes),
/ tests/analysis/divergences.txt gives the expected lines instead.
.joinTest.cases:.joinTest.readBlocks "tests/analysis/join_golden.txt";
.joinTest.divergent:.joinTest.readBlocks "tests/analysis/divergences.txt";
.joinTest.expected:.joinTest.cases,.joinTest.divergent;   / divergences win
.joinTest.headers:key .joinTest.cases;
.joinTest.k:0;
while[.joinTest.k < count .joinTest.headers;
  header:string .joinTest.headers .joinTest.k;
  parts:"\t" vs 4 _ header;          / 4 _ drops "=== "
  .test.checkLines[header; .joinTest.caseLines[`$parts 0; 1 _ parts]; .joinTest.expected `$header];
  .joinTest.k+:1];


/ joinFilters[r]
/   Every Filter node of plan r whose source has a join, parent first,
/   then children left to right.
.joinTest.joinFilters:{[r]
  out:();
  if[`Filter = .aqc.nodes.name r;
    if[.aqc.join.hasJoin r`t; out:.aqc.nodes.one r]];
  kids:.aqc.nodes.planChildren r;
  k:0;
  while[k < count kids;
    out:.aqc.ast.concat[out; .joinTest.joinFilters kids k];
    k+:1];
  out};

/ planLines[label; r]
/   The lines for one query plan (none if it has no join).
.joinTest.planLines:{[label;r]
  if[not .aqc.join.hasJoin r; :()];
  out:("PLAN\t",label; "AVAIL\t",.joinTest.namesText .aqc.join.tablesAvailable r);
  out,:.joinTest.treeLines[.aqc.join.annotate r; ""; ()];
  filters:.joinTest.joinFilters r;
  k:0;
  while[k < count filters;
    f:filters k;
    conds:f`fs;
    / place the last condition first (the optimizer's foldRight)
    acc:f`t;
    i:(count conds) - 1;
    while[i >= 0;
      acc:.aqc.join.placeFilter[acc; conds i];
      i-:1];
    out,:enlist "PLACE\t",string k + 1;
    out,:.joinTest.treeLines[acc; ""; conds];
    k+:1];
  out};

/ queryLines[n; q]
/   The lines for every plan of Query node q (statement number n).
.joinTest.queryLines:{[n;q]
  out:();
  k:0;
  while[k < count q`local;
    l:(q`local) k;
    out,:.joinTest.planLines[(string n)," local ",.aqc.tc.err.str l`_1; l`_3];
    k+:1];
  out,.joinTest.planLines[(string n)," main"; q`main]};

/ fileLines[path]
/   The lines for every query plan with a join in a program file.
.joinTest.fileLines:{[path]
  prog:.aqc.gen.parseText "\n" sv read0 hsym `$path;
  out:();
  k:0;
  while[k < count prog;
    s:prog k;
    n:.aqc.nodes.name s;
    if[n = `Query; out,:.joinTest.queryLines[k + 1; s]];
    if[n = `Create;
      if[`Right ~ (s`source)`node; out,:.joinTest.queryLines[k + 1; (s`source)`value]]];
    k+:1];
  out};

/ Every program in join_plans_golden.txt.
.joinTest.plans:.joinTest.readBlocks "tests/analysis/join_plans_golden.txt";
.joinTest.files:key .joinTest.plans;
.joinTest.k:0;
while[.joinTest.k < count .joinTest.files;
  header:string .joinTest.files .joinTest.k;
  .test.checkLines[header; .joinTest.fileLines 4 _ header; .joinTest.plans `$header];
  .joinTest.k+:1];


/ A few checks that read well on their own.
.joinTest.expr:{[text] .aqc.parse.parseRule[.aqc.parse.expr; text]`node};
.test.check["tablesUsed of t.c1 + u.c2"; .aqc.join.tablesUsed .joinTest.expr "t.c1 + u.c2"; `t`u];
.test.check["c1 makes the tables unknown"; .aqc.join.isUnknown .aqc.join.tablesUsed .joinTest.expr "t.c1 + c2"; 1b];
.test.check["no columns: no tables"; .aqc.join.tablesUsed .joinTest.expr "1 + 2"; `symbol$()];

.test.finish[];
