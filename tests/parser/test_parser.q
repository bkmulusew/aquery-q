/ test_parser.q - hand-written unit tests for the parser, one group per
/ grammar rule. Each test parses a short string with one rule and checks
/ the tree.

/ Run from the aquery-q folder:   bin/l_m64 tests/parser/test_parser.q

/ Every expected value below was printed by the real Scala parser with
/   java -cp aquery.jar:tools RuleDump expr '<text>'
/ (tools/RuleDump.java). Scala prints a tree on one line, e.g.
/ BinExpr(Plus,IntLit(1),Id(x)); .aqc.ast.show prints ours the same way.
/ For a failure only the position is compared (see tests/parser/README.md).
/ The golden files (test_golden.q) cover whole programs; these tests pin
/ down each rule on its own so a failure points straight at the broken rule.


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ expr[src]
/   Parse all of src as one expression and show the result on one line:
/   the tree as Scala prints it, or "FAILURE line:col".
expr:{[src] .aqc.parse.showRule[.aqc.parse.expr;src]};

/ checkExpr[src; expected]
/   One test: expr src must be expected. The test is named after src.
checkExpr:{[src;expected] .test.check["expr: ",src;expr src;expected]};


/ ---------------------------------------------------------------------------
/ Operators and precedence
/ ---------------------------------------------------------------------------

checkExpr["2 * 3 + 4 / 5 + 7";
  "BinExpr(Plus,BinExpr(Plus,BinExpr(Times,IntLit(2),IntLit(3)),BinExpr(Div,IntLit(4),IntLit(5))),IntLit(7))"];
checkExpr["f(g(1,2,3), h()) + (3 + 4)";
  "BinExpr(Plus,FunCall(f,List(FunCall(g,List(IntLit(1), IntLit(2), IntLit(3))), FunCall(h,List()))),BinExpr(Plus,IntLit(3),IntLit(4)))"];
/ every comparison and logical operator, lowest precedence last
checkExpr["a < b <= c = d != e & f | g";
  "BinExpr(Lor,BinExpr(Land,BinExpr(Neq,BinExpr(Eq,BinExpr(Le,BinExpr(Lt,Id(a),Id(b)),Id(c)),Id(d)),Id(e)),Id(f)),Id(g))"];
/ there is no unary +
checkExpr["2 / +3"; "FAILURE 1:5"];
/ the lexer makes tokens for <> and ==, but no rule uses them
checkExpr["a <> 1"; "FAILURE 1:3"];
checkExpr["a == 1"; "FAILURE 1:3"];
/ ! on its own is not a token (the lexer reports an error there)
checkExpr["x !y"; "FAILURE 1:4"];
/ unfinished input
checkExpr["1 +"; "FAILURE 1:4"];
checkExpr["(1 + 2"; "FAILURE 1:7"];


/ ---------------------------------------------------------------------------
/ Unary minus and ^
/ ---------------------------------------------------------------------------

/ - binds tighter than ^ (a Scala quirk, copied)
checkExpr["-x^2"; "BinExpr(Exp,UnExpr(Neg,Id(x)),IntLit(2))"];
/ a negated number is folded into the literal, also inside parentheses
checkExpr["- 1.50"; "FloatLit(-1.5)"];
checkExpr["-(1)"; "IntLit(-1)"];
checkExpr["-f(x)"; "UnExpr(Neg,FunCall(f,List(Id(x))))"];
checkExpr["2^-3"; "BinExpr(Exp,IntLit(2),IntLit(-3))"];
/ ^ groups to the right
checkExpr["2^3^4"; "BinExpr(Exp,IntLit(2),BinExpr(Exp,IntLit(3),IntLit(4)))"];


/ ---------------------------------------------------------------------------
/ CASE
/ ---------------------------------------------------------------------------

checkExpr["CASE WHEN x > 2 THEN 3 WHEN x < 0 THEN 4 * 10 END";
  "Case(None,List(IfThen(BinExpr(Gt,Id(x),IntLit(2)),IntLit(3)), IfThen(BinExpr(Lt,Id(x),IntLit(0)),BinExpr(Times,IntLit(4),IntLit(10)))),None)"];
checkExpr["CASE WHEN x > 2 THEN 3 WHEN x < 0 THEN 4 * 10 ELSE f() END";
  "Case(None,List(IfThen(BinExpr(Gt,Id(x),IntLit(2)),IntLit(3)), IfThen(BinExpr(Lt,Id(x),IntLit(0)),BinExpr(Times,IntLit(4),IntLit(10)))),Some(FunCall(f,List())))"];
checkExpr["case f(x) WHEN 3 THEN 4 ELSE 5 END";
  "Case(Some(FunCall(f,List(Id(x)))),List(IfThen(IntLit(3),IntLit(4))),Some(IntLit(5)))"];
checkExpr["case g() WHEN 1 THEN (case WHEN y > 0 then 0 END) END";
  "Case(Some(FunCall(g,List())),List(IfThen(IntLit(1),Case(None,List(IfThen(BinExpr(Gt,Id(y),IntLit(0)),IntLit(0))),None))),None)"];
/ missing END; missing WHEN
checkExpr["CASE WHEN x > 2 THEN 3 "; "FAILURE 1:24"];
checkExpr["CASE x >2 THEN 3"; "FAILURE 1:11"];


/ ---------------------------------------------------------------------------
/ Indexing: x[even], x[odd], x[every n]
/ ---------------------------------------------------------------------------

/ a literal is never indexed (Scala tries lit first)
checkExpr["5[even]"; "FAILURE 1:2"];
checkExpr["(a)[even]"; "ArrayIndex(Id(a),Even)"];
checkExpr["f(x)[odd][every 2]"; "ArrayIndex(ArrayIndex(FunCall(f,List(Id(x))),Odd),Every(2))"];
/ only even, odd and every n can go inside [ ]
checkExpr["a[x]"; "FAILURE 1:3"];


/ ---------------------------------------------------------------------------
/ Function calls, columns, literals
/ ---------------------------------------------------------------------------

/ built-in function names are stored in capitals; Sum is not a keyword
/ spelling (only SUM and sum are), so it is an ordinary identifier
checkExpr["sum(x) + SUM(y) + Sum(z)";
  "BinExpr(Plus,BinExpr(Plus,FunCall(SUM,List(Id(x))),FunCall(SUM,List(Id(y)))),FunCall(Sum,List(Id(z))))"];
checkExpr["not(x)"; "FunCall(NOT,List(Id(x)))"];
checkExpr["f()"; "FunCall(f,List())"];
checkExpr["t.c * ROWID"; "BinExpr(Times,ColumnAccess(t,c),RowId)"];
checkExpr["*"; "WildCard"];
/ t.c is one column; a second "." has nothing to attach to
checkExpr["a.b.c"; "FAILURE 1:4"];
checkExpr["(1)"; "IntLit(1)"];
checkExpr["'01/02/2020'"; "DateLit(01/02/2020)"];
checkExpr["\"s\" = TRUE"; "BinExpr(Eq,StringLit(s),BooleanLit(true))"];
checkExpr["false"; "BooleanLit(false)"];
/ numbers: a "." makes a FloatLit, printed the way Java prints doubles
checkExpr["100.00"; "FloatLit(100.0)"];
checkExpr["10000000.0"; "FloatLit(1.0E7)"];
checkExpr["0.0001"; "FloatLit(1.0E-4)"];
checkExpr["3.14159265358979"; "FloatLit(3.14159265358979)"];
checkExpr["007"; "IntLit(7)"];

/ INTENTIONAL DIVERGENCE: Scala gives StringLit(01/02/2020D10:11:12)
checkExpr["'01/02/2020D10:11:12'"; "TimestampLit(01/02/2020D10:11:12)"];


/ ---------------------------------------------------------------------------
/ Positions: the indented golden-file format, with @line:col
/ (expected lines printed by: java ... RuleDump -tree expr '<text>')
/ ---------------------------------------------------------------------------

/ tree[src]: parse src as an expression and give the golden-format lines
tree:{[src] .aqc.ast.format[0;"";(.aqc.parse.parseRule[.aqc.parse.expr;src])`node]};

.test.checkLines["tree: CASE with Some, IfThen and Every";
  tree "CASE f(x) WHEN 1 THEN - 2 ELSE (a)[every 3] END";
  ("Case @1:1";
   "  cond: Some";
   "    value: FunCall @1:6";
   "      f: \"f\"";
   "      args: List";
   "        - Id @1:8";
   "          v: \"x\"";
   "  when: List";
   "    - IfThen";
   "      c: IntLit @1:16";
   "        v: 1";
   "      t: IntLit @1:23";
   "        v: -2";
   "  e: Some";
   "    value: ArrayIndex @1:32";
   "      e: Id @1:33";
   "        v: \"a\"";
   "      ix: Every";
   "        v: 3")];

.test.checkLines["tree: a chain of operators starts where its first operand does";
  tree "x ^ y * t.c";
  ("BinExpr @1:1";
   "  op: Times";
   "  l: BinExpr @1:1";
   "    op: Exp";
   "    l: Id @1:1";
   "      v: \"x\"";
   "    r: Id @1:5";
   "      v: \"y\"";
   "  r: ColumnAccess @1:9";
   "    t: \"t\"";
   "    c: \"c\"")];


/ ---------------------------------------------------------------------------
/ Helpers in ast.q
/ ---------------------------------------------------------------------------

.test.check["javaDouble 1.5"; .aqc.ast.javaDouble 1.5; "1.5"];
.test.check["javaDouble 100"; .aqc.ast.javaDouble 100f; "100.0"];
.test.check["javaDouble 0"; .aqc.ast.javaDouble 0f; "0.0"];
.test.check["javaDouble -2.25"; .aqc.ast.javaDouble -2.25; "-2.25"];
.test.check["javaDouble 0.001"; .aqc.ast.javaDouble 0.001; "0.001"];
.test.check["javaDouble 1e7"; .aqc.ast.javaDouble 1e7; "1.0E7"];
.test.check["javaDouble 1.25e8"; .aqc.ast.javaDouble 1.25e8; "1.25E8"];
.test.check["javaDouble 0.0001"; .aqc.ast.javaDouble 0.0001; "1.0E-4"];

/ two nodes with the same keys in one list (q may store it as a table)
twoIds:.aqc.ast.append[.aqc.ast.append[();.aqc.ast.id "a"];.aqc.ast.id "b"];
.test.check["append: count"; count twoIds; 2];
.test.check["append: second item"; (twoIds 1)`v; "b"];
.test.check["show: list of same-shaped nodes"; .aqc.ast.show twoIds; "List(Id(a), Id(b))"];
.test.check["show: empty list"; .aqc.ast.show (); "List()"];
.test.check["format: empty list"; .aqc.ast.format[0;"args: ";()]; enlist "args: []"];


.test.finish[];
