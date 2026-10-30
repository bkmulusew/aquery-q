/ test_expr.q - test the q code made for expressions (src/codegen/expr.q,
/ src/codegen/state.q).

/ Two parts:
/ 1. Hand-written checks, one or more per rule in expr.q, with the
/    expected q code written out. They show what each rule does.
/ 2. Golden files: tools/gen_expr_golden.sh ran the Scala code generator
/    on every expression of every input that the jar can parse
/    (tools/GenDump.java), in four states, and saved the result in
/    tests/codegen/expr_golden/<path>.txt. This file parses the same input
/    with the q parser, visits the expressions in the same order, and
/    checks every line is identical.

/ Run from the aquery-q folder:   bin/l_m64 tests/codegen/test_expr.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q
\l tests/lib/jar_fixes.q


/ ---------------------------------------------------------------------------
/ 1. Hand-written checks
/ ---------------------------------------------------------------------------

/ Short names for building trees by hand.
id:.aqc.ast.id;
int:{[v] .aqc.ast.lit[`IntLit; v]};
/ gen[e]: the code for e in a fresh state
gen:{[e] .aqc.gen.st:.aqc.gen.fresh[]; .aqc.gen.expr e};

/ State helpers
.aqc.gen.st:.aqc.gen.fresh[];
.test.check["fresh state: not grouped"; .aqc.gen.get `grouped; 0b];
.test.check["newTableName: first"; .aqc.gen.newTableName[]; "aq__t0"];
.test.check["newTableName: second"; .aqc.gen.newTableName[]; "aq__t1"];
.aqc.gen.set[`queryId; 5];
.aqc.gen.set[`grouped; 1b];
.aqc.gen.cleanQueryEnv[];
.test.check["cleanQueryEnv keeps tableId"; .aqc.gen.get `tableId; 2];
.test.check["cleanQueryEnv keeps queryId"; .aqc.gen.get `queryId; 5];
.test.check["cleanQueryEnv resets grouped"; .aqc.gen.get `grouped; 0b];
.aqc.gen.cleanTopEnv[];
.test.check["cleanTopEnv resets tableId"; .aqc.gen.get `tableId; 0];
.test.check["cleanTopEnv keeps queryId"; .aqc.gen.get `queryId; 5];

/ Function names
.test.check["funName: built-in with arity"; .aqc.gen.funName["SUMS"; 1]; ".aq.sums1"];
.test.check["funName: built-in, other arity"; .aqc.gen.funName["sums"; 2]; ".aq.sums2"];
.test.check["funName: plain built-in"; .aqc.gen.funName["Avg"; 1]; ".aq.avg"];
.test.check["funName: exec_arrays is plain"; .aqc.gen.funName["exec_arrays"; 1]; ".aq.exec_arrays"];
.test.check["funName: not a built-in keeps its case"; .aqc.gen.funName["myF"; 2]; "myF"];
.test.check["funName: arity built-in with no such arity"; .aqc.gen.funName["prev"; 3]; "prev"];

/ Literals
.test.check["IntLit"; gen int 42; "42"];
.test.check["negative IntLit"; gen int -3; "-3"];
.test.check["FloatLit"; gen .aqc.ast.lit[`FloatLit; 100f]; "100.0"];
.test.check["FIXED: StringLit is an enlisted symbol"; gen .aqc.ast.lit[`StringLit; "IBM"]; "(enlist `$\"IBM\")"];
.test.check["DateLit"; gen .aqc.ast.lit[`DateLit; "01/02/2020"]; "\"D\"$\"01/02/2020\""];
.test.check["TimestampLit"; gen .aqc.ast.lit[`TimestampLit; "01/02/2020D10:00:00"]; "\"P\"$\"01/02/2020D10:00:00\""];
.test.check["BooleanLit"; gen .aqc.ast.lit[`BooleanLit; 0b]; "0b"];

/ Names, columns, ROWID and *
.test.check["Id is a column lookup"; gen id "price"; "{x^.aq.cd x} `price"];
.aqc.gen.st:.aqc.gen.fresh[];
.aqc.gen.set[`nameAsVar; 1b];
.test.check["Id with nameAsVar"; .aqc.gen.expr id "price"; "price"];
.aqc.gen.set[`inUDF; 1b];
.test.check["Id inside a FUNCTION"; .aqc.gen.expr id "price"; ".aq.funEnlist price"];
.test.check["one-letter Id (a char atom)"; gen id "a"; "{x^.aq.cd x} `a"];
.test.check["ColumnAccess"; gen .aqc.ast.columnAccess["t";"price"]; "{x^.aq.cd x} `t.price"];
.test.check["ROWID"; gen `RowId; "`i"];
.aqc.gen.st:.aqc.gen.fresh[];
.aqc.gen.set[`currTable; "aq__t3"];
.test.check["* is the current table's columns"; .aqc.gen.expr `WildCard; "(.aq.wildCard aq__t3)"];
.test.check["TableColumnValue"; gen .aqc.ast.tableColumnValue["DateInfo";"startYear"]; "DateInfo`startYear"];

/ Operators
.test.check["BinExpr"; gen .aqc.ast.binExpr[`Plus; id "a"; int 1]; "(+; {x^.aq.cd x} `a; 1)"];
.test.check["BinExpr: / is %"; gen .aqc.ast.binExpr[`Div; int 1; int 2]; "(%; 1; 2)"];
.test.check["BinExpr: ^ is .aq.pow"; gen .aqc.ast.binExpr[`Exp; int 1; int 2]; "(.aq.pow; 1; 2)"];
.test.check["BinExpr: != is <>"; gen .aqc.ast.binExpr[`Neq; int 1; int 2]; "(<>; 1; 2)"];
.test.check["UnExpr (FIXED: no stray })"; gen .aqc.ast.unExpr[`Neg; id "a"]; "(.aq.neg; {x^.aq.cd x} `a)"];
.test.check["UnExpr: NOT"; gen .aqc.ast.unExpr[`Not; id "a"]; "(.aq.not; {x^.aq.cd x} `a)"];

/ Function calls
.test.check["FunCall"; gen .aqc.ast.funCall["f"; (id "a"; int 2)]; "(f;{x^.aq.cd x} `a;2)"];
.test.check["FunCall: built-in"; gen .aqc.ast.funCall["SUM"; .aqc.nodes.one id "a"]; "(.aq.sum;{x^.aq.cd x} `a)"];
.test.check["FunCall: no arguments"; gen .aqc.ast.funCall["f"; ()]; "(f;)"];
.test.check["COUNT(*) counts ROWID"; gen .aqc.ast.funCall["COUNT"; enlist `WildCard]; "(.aq.count;`i)"];
.test.check["variadic call"; gen .aqc.ast.funCall["concatenate"; (id "a"; id "b")];
  "(.aq.concatenate;(enlist;{x^.aq.cd x} `a;{x^.aq.cd x} `b))"];
.test.check["IN a WITH column gets enlist";
  gen .aqc.ast.funCall["IN"; .aqc.nodes.two[id "a"; .aqc.ast.tableColumnValue["w";"c"]]];
  "(.aq.in;{x^.aq.cd x} `a;enlist w`c)"];
.aqc.gen.st:.aqc.gen.fresh[];
.aqc.gen.set[`grouped; 1b];
.test.check["FunCall after GROUP BY uses each"; .aqc.gen.expr .aqc.ast.funCall["avg"; .aqc.nodes.one id "a"];
  "(.aq.avg';{x^.aq.cd x} `a)"];

/ Array index and CASE
.test.check["x[EVEN]"; gen .aqc.ast.arrayIndex[id "a"; `Even]; "(.aq.indexEven; {x^.aq.cd x} `a)"];
.test.check["x[EVERY 3]"; gen .aqc.ast.arrayIndex[id "a"; .aqc.ast.every 3];
  "(.aq.indexEveryN[3; ]; {x^.aq.cd x} `a)"];
caseNoValue:.aqc.ast.case[`None; .aqc.nodes.one .aqc.ast.ifThen[.aqc.ast.binExpr[`Gt; id "a"; int 1]; int 1]; .aqc.ast.some int 0];
.test.check["CASE WHEN ... ELSE"; gen caseNoValue;
  "(.aq.cond; ();(enlist;(enlist;(>; {x^.aq.cd x} `a; 1); 1)); 0)"];
caseValue:.aqc.ast.case[.aqc.ast.some id "a"; .aqc.nodes.two[.aqc.ast.ifThen[int 1; int 10]; .aqc.ast.ifThen[int 2; int 20]]; `None];
.test.check["CASE x WHEN ... WHEN ..., no ELSE"; gen caseValue;
  "(.aq.cond; {x^.aq.cd x} `a;(enlist;(enlist;1; 10);(enlist;2; 20)); ())"];

/ Lists of expressions
.aqc.gen.st:.aqc.gen.fresh[];
.test.check["exprList: empty"; .aqc.gen.exprList[(); 1b]; "()"];
.test.check["exprList: one, wrapped"; .aqc.gen.exprList[.aqc.nodes.one id "a"; 1b]; "enlist ({x^.aq.cd x} `a)"];
.test.check["exprList: two, wrapped"; .aqc.gen.exprList[(int 1; int 2); 1b]; "(1;2)"];
.test.check["exprList: two, not wrapped"; .aqc.gen.exprList[(int 1; int 2); 0b]; "1;2"];
.test.check["exprDict: one"; .aqc.gen.exprDict[enlist (id "a"; "x"); .aqc.gen.sym]; "(enlist[`x]!enlist {x^.aq.cd x} `a)"];
.test.check["exprDict: two"; .aqc.gen.exprDict[((int 1; "x"); (int 2; "y")); .aqc.gen.sym]; "((`x);(`y))!(1;2)"];
.aqc.gen.set[`currTable; "aq__t0"];
.test.check["exprDict: * alone"; .aqc.gen.exprDict[enlist (`WildCard; "*"); .aqc.gen.sym]; "(.aq.wildCard aq__t0)"];
.test.check["exprDict: * and a column"; .aqc.gen.exprDict[((`WildCard; "*"); (int 1; "x")); .aqc.gen.sym];
  "(.aq.wildCard aq__t0),(enlist[`x]!enlist 1)"];
.test.check["exprDict: column lookup keys"; .aqc.gen.exprDict[enlist (id "a"; "a"); .aqc.gen.colLookup];
  "(enlist[{x^.aq.cd x} `a]!enlist {x^.aq.cd x} `a)"];


/ ---------------------------------------------------------------------------
/ 2. Golden files
/ ---------------------------------------------------------------------------

/ The expression node names (src/ast/nodes.q has the leaves).
.exprTest.exprNames:.aqc.nodes.leafExprs,`BinExpr`UnExpr`FunCall`ArrayIndex`Case`IfThen;

/ The four states of tools/GenDump.java: (label; grouped; nameAsVar; inUDF)
.exprTest.states:(("plain";0b;0b;0b); ("grouped";1b;0b;0b); ("nameAsVar";0b;1b;0b); ("udf";0b;1b;1b));

/ genIn[state; e]
/   The golden line for expression e in one state: "label<TAB>code",
/   with the code escaped like the golden files, or ERROR.
.exprTest.genIn:{[state;e]
  .aqc.gen.st:.aqc.gen.fresh[];
  .aqc.gen.set[`currTable; "aq__t0"];
  .aqc.gen.set[`grouped; state 1];
  .aqc.gen.set[`nameAsVar; state 2];
  .aqc.gen.set[`inUDF; state 3];
  / @[f; x; handler] calls f x, or handler on an error
  code:@[.aqc.gen.expr; e; {[err] "ERROR"}];
  (state 0),"\t",$["ERROR" ~ code; code; .aqc.ast.escape code]};

/ linesFor[x]
/   The golden lines for every expression inside x, in the order GenDump
/   visits them: x itself if it is an expression (but not an IfThen),
/   then the fields of a node in order, or the items of a list.
.exprTest.linesFor:{[x]
  t:type x;
  if[t in 10 -10h; :()];                        / a string
  if[t = -11h;                                  / a symbol: ROWID, * or a constant
    if[not x in `RowId`WildCard; :()]];
  if[.aqc.ast.isList x;
    out:();
    k:0;
    while[k < count x; out,:.exprTest.linesFor x k; k+:1];
    :out];
  if[not (t = -11h) or .aqc.ast.isNode x; :()];  / numbers, booleans
  out:();
  n:.aqc.nodes.name x;
  if[(n in .exprTest.exprNames) and not n = `IfThen;
    out,:enlist "--- ",.aqc.ast.escape .aqc.ast.show x;
    k:0;
    while[k < count .exprTest.states; out,:enlist .exprTest.genIn[.exprTest.states k; x]; k+:1]];
  if[t = -11h; :out];
  fields:.aqc.ast.fields x;
  k:0;
  while[k < count fields; out,:.exprTest.linesFor x fields k; k+:1];
  out};

/ programLines[inputPath]
/   The golden lines for the program in a file (FAILURE if it does not
/   parse; then it should have no golden file).
.exprTest.programLines:{[inputPath]
  text:.aqc.util.normalizeLines .aqc.util.readFile inputPath;
  r:.aqc.parse.parseRule[.aqc.parse.program; text];
  if[not r`ok; :enlist "FAILURE"];
  .exprTest.linesFor r`node};

inputFor:.test.inputFor["tests/codegen/expr_golden"];
goldens:.test.findFiles["tests/codegen/expr_golden"; ".txt"];
-1 "golden files: ",string count goldens;
i:0;
while[i < count goldens;
  goldenPath:goldens i;
  inputPath:inputFor goldenPath;
  / the golden code is escaped, so its strings look like `$\"IBM\"
  expected:.jarFix.stringLits["\\\""] each read0 hsym `$goldenPath;
  .test.checkLines[inputPath; .exprTest.programLines inputPath; expected];
  i+:1];

.test.finish[];
