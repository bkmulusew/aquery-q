/ test_nodes.q - test the AST helpers (src/ast/nodes.q) against Scala.

/ Every case in tests/ast/helper_cases.txt names a grammar rule and a piece
/ of text. tools/gen_helper_golden.sh parsed each one with the real Scala
/ parser, called the Scala helpers on the tree (tools/HelperDump.java) and
/ saved what they returned in tests/ast/helper_golden.txt. This file does
/ the same with the q parser and the q helpers and checks the results are
/ identical, positions included. A few hand-written checks at the end
/ cover the attr helpers, which have no Scala output to compare with.

/ Run from the aquery-q folder:   bin/l_m64 tests/ast/test_nodes.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The q rule for each rule name used in helper_cases.txt.
.nodeTest.rules:`expr`predicate`query!(.aqc.parse.expr; .aqc.parse.predicate; .aqc.parse.query);


/ readCases[path]
/   The cases in a helper_golden.txt file. Each case there starts with a
/   line "=== rule<TAB>text", followed by the expected lines.
/   returns: list of 3-item lists (rule name symbol; text; expected lines)
/   (the same layout as tests/parser/rule_golden.txt)
.nodeTest.readCases:{[path]
  lines:read0 hsym `$path;
  starts:where {"=== " ~ 4#x} each lines;
  blocks:starts cut lines;        / cut splits lines at each start index
  cases:();
  k:0;
  while[k < count blocks;
    block:blocks k;
    header:4 _ first block;       / "rule<TAB>text"
    tab:header ? "\t";            / ? finds the first tab
    rule:`$tab # header;
    text:(tab + 1) _ header;
    cases,:enlist (rule;text;1 _ block);
    k+:1];
  cases};


/ section[title; v]
/   One helper's result as golden lines: "--- title", then v as a tree.
.nodeTest.section:{[title;v] (enlist "--- ",title),.aqc.ast.format[0;"";v]};

/ isA[name; x]  and  isNotA[name; x]
/   The predicates HelperDump.java uses: is plan node x a `name node?
.nodeTest.isA:{[name;x] name = x`node};
.nodeTest.isNotA:{[name;x] not name = x`node};

/ renameTables[x]  and  dropSort[x]
/   The transforms HelperDump.java uses:
/   { case Table(n, a, attr) => Table(n + "_t", a, attr) }
/   { case SortBy(t, _, _) => t }
.nodeTest.renameTables:{[x]
  if[not `Table = x`node; :x];
  x[`n]:x[`n],"_t";
  x};
.nodeTest.dropSort:{[x] $[`SortBy = x`node; x`t; x]};

/ exprSections[e] and planSections[r]
/   Every helper result for an expression / a plan, in HelperDump's order.
.nodeTest.exprSections:{[e]
  .nodeTest.section["children"; .aqc.nodes.exprChildren e],
  .nodeTest.section["allSubExpressions"; .aqc.nodes.allSubExpressions e]};

.nodeTest.planSections:{[r]
  out:.nodeTest.section["children"; .aqc.nodes.planChildren r];
  out,:.nodeTest.section["expr"; .aqc.nodes.planExprs r];
  out,:.nodeTest.section["find Table"; .aqc.nodes.find[.nodeTest.isA[`Table]; r]];
  out,:.nodeTest.section["find SortBy"; .aqc.nodes.find[.nodeTest.isA[`SortBy]; r]];
  out,:.nodeTest.section["find Join"; .aqc.nodes.find[.nodeTest.isA[`Join]; r]];
  / {[x] x} is the identity function: takeWhile keeps the nodes themselves
  out,:.nodeTest.section["takeWhile notSortBy"; .aqc.nodes.takeWhile[.nodeTest.isNotA[`SortBy]; {[x] x}; r]];
  out,:.nodeTest.section["transform renameTables"; .aqc.nodes.transform[.nodeTest.renameTables; r]];
  out,:.nodeTest.section["transform dropSort"; .aqc.nodes.transform[.nodeTest.dropSort; r]];
  out};

/ actual[rule; text]
/   Parse text with rule (a symbol from .nodeTest.rules) and give every
/   helper result as golden lines, or one line "FAILURE" if it does not
/   parse.
.nodeTest.actual:{[rule;text]
  r:.aqc.parse.parseRule[.nodeTest.rules rule; text];
  if[not r`ok; :enlist "FAILURE"];
  $[`query = rule; .nodeTest.planSections r`node; .nodeTest.exprSections r`node]};


/ ---------------------------------------------------------------------------
/ Golden cases
/ ---------------------------------------------------------------------------

cases:.nodeTest.readCases "tests/ast/helper_golden.txt";
-1 "helper cases: ",string count cases;

i:0;
while[i < count cases;
  c:cases i;
  name:(string c 0),": ",c 1;
  .test.checkLines[name; .nodeTest.actual[c 0; c 1]; c 2];
  i+:1];


/ ---------------------------------------------------------------------------
/ attr (no Scala output: hand-written)
/ ---------------------------------------------------------------------------

table:(.aqc.parse.parseRule[.aqc.parse.query; "SELECT a FROM t"]`node)`t;

.test.check["attrs of a parsed node are empty"; .aqc.nodes.attrs table; ()!()];
.test.check["getAttr gives the default when unset"; .aqc.nodes.getAttr[table; `TABLES_AVAIL; 0]; 0];

withAttr:.aqc.nodes.setAttr[table; `TABLES_AVAIL; enlist "t"];
.test.check["getAttr gives what setAttr stored"; .aqc.nodes.getAttr[withAttr; `TABLES_AVAIL; 0]; enlist "t"];
twoAttrs:.aqc.nodes.setAttr[withAttr; `OTHER; 42];
.test.check["setAttr keeps other attributes"; .aqc.nodes.getAttr[twoAttrs; `TABLES_AVAIL; 0]; enlist "t"];
.test.check["setAttr replaces a value"; .aqc.nodes.getAttr[.aqc.nodes.setAttr[twoAttrs; `OTHER; 7]; `OTHER; 0]; 7];
.test.check["clearAttr removes every attribute"; .aqc.nodes.clearAttr twoAttrs; table];
.test.check["printed trees leave attr out"; .aqc.ast.format[0;"";withAttr]; .aqc.ast.format[0;"";table]];
.test.check["show leaves attr out"; .aqc.ast.show withAttr; .aqc.ast.show table];

/ transform keeps attributes (Scala passes attr to the rebuilt node)
plan:.aqc.parse.parseRule[.aqc.parse.query; "SELECT a FROM t"]`node;
plan[`t]:withAttr;
same:.aqc.nodes.transform[{[x] x}; plan];
.test.check["transform keeps attr"; .aqc.nodes.getAttr[same`t; `TABLES_AVAIL; 0]; enlist "t"];

.test.finish[];
