/ expr.q - q code for expressions.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/codegen/
/ KdbGenerator.scala: genExpr and everything it calls (genBinExpr,
/ genUnExpr, genId, genLit, genFunCall, genCaseExpr, genArrayIndex,
/ genTableExpr, genTableColumnValue), plus the list helpers the plan
/ code uses (genExprList, genExprDict).
/ The output is byte for byte what the jar prints, so Scala's odd corners
/ are copied on purpose (each one is marked SCALA QUIRK). The real bugs
/ are fixed instead (each one is marked FIXED, and the programs whose
/ output changes are listed in tests/codegen/divergences.txt).

/ WHAT THE CODE LOOKS LIKE
/ An expression becomes a q parse tree written as text, which the
/ generated program later runs through q's functional select (?[t;w;b;c])
/ or eval. A parse tree is a list: the function first, then its arguments.
/     a + 1      becomes   (+; {x^.aq.cd x} `a; 1)
/     f(a, 2)    becomes   (f;{x^.aq.cd x} `a;2)
/ {x^.aq.cd x} `a looks up column a (.aq.cd is a helper in base.q).
/ Spacing differs from one kind of expression to the next; it is copied
/ from Scala exactly.

/ Expressions only read the state (src/codegen/state.q), never change it.


/ ---------------------------------------------------------------------------
/ Names of functions
/ ---------------------------------------------------------------------------

/ AQuery functions that base.q defines as .aq.<name>. A name with _N is
/ the version for N arguments: avgs with 1 argument is .aq.avgs1, with 2
/ it is .aq.avgs2 (Scala: BUILT_INS).
/ SCALA QUIRK: exec_arrays is split at "_" too, but "arrays" is not a
/ number, so Scala keeps it as a plain name.
.aqc.gen.plainBuiltIns:`abs`and`avg`between`concatenate`count`deltas`distinct,
  `drop`list`exec_arrays`flatten`fill`is`in`indexEven`indexOdd,
  `indexEveryN`like`makeNull`max`min`mod`moving`not`null`or`overlaps`pow,
  `prd`prds`ratios`reverse`show`sum`sqrt`stddev`toSym`vars;
.aqc.gen.arityBuiltIns:`avgs_1`avgs_2`first_1`first_2`last_1`last_2`maxs_1`maxs_2,
  `mins_1`mins_2`next_1`next_2`prev_1`prev_2`sums_1`sums_2;

/ Functions whose arguments are passed as one list, (f;(enlist;a;b;c)),
/ because they take any number of them (Scala: VARIADIC).
.aqc.gen.variadic:`and`concatenate`or`list;

/ funName[f; nargs]
/   The q name to call for AQuery function f with nargs arguments
/   (Scala: genFunName). Built-ins are matched in lower case.
/     funName["SUMS"; 1]   is ".aq.sums1"
/     funName["avg"; 1]    is ".aq.avg"
/     funName["myF"; 2]    is "myF"      (not a built-in: kept as written)
.aqc.gen.funName:{[f;nargs]
  / (lowerName, not lower: L does not allow a q built-in as a local name)
  lowerName:lower .aqc.gen.str f;
  if[(`$lowerName,"_",string nargs) in .aqc.gen.arityBuiltIns; :".aq.",lowerName,string nargs];
  if[(`$lowerName) in .aqc.gen.plainBuiltIns; :".aq.",lowerName];
  .aqc.gen.str f};

/ sameName[f; name]
/   Is the function name f the same as name, ignoring case?
/   (Scala: equalsIgnoreCase)
/     sameName["Count"; "count"]   is 1b
.aqc.gen.sameName:{[f;name] (lower .aqc.gen.str f) ~ name};


/ ---------------------------------------------------------------------------
/ Expressions (Scala: genExpr)
/ ---------------------------------------------------------------------------

/ The q text for each binary operator (Scala: genBinOp).
.aqc.gen.binOps:`Plus`Minus`Times`Div`Exp`Lt`Le`Gt`Ge`Eq`Neq`Land`Lor!
  (enlist "+";enlist "-";enlist "*";enlist "%";".aq.pow";enlist "<";"<=";enlist ">";">=";enlist "=";"<>";enlist "&";enlist "|");

/ The q function for each unary operator (Scala: genUnOp).
.aqc.gen.unOps:`Neg`Not!(".aq.neg";".aq.not");

/ expr[e]
/   PUBLIC. The q code for expression e (Scala: genExpr).
/     expr <a + 1>      is "(+; {x^.aq.cd x} `a; 1)"
/     expr <"IBM">      is "`$\"IBM\""
/   Signals an error for anything that is not an expression. IfThen (one
/   WHEN ... THEN pair) is not an expression on its own here either: only
/   caseExpr handles it, as in Scala.
.aqc.gen.expr:{[e]
  n:.aqc.nodes.name e;
  if[n = `BinExpr;
    :"(",(.aqc.gen.binOps e`op),"; ",(.aqc.gen.expr e`l),"; ",(.aqc.gen.expr e`r),")"];
  / FIXED: Scala writes a stray "}" after the operator, (.aq.neg}; ...),
  / which q cannot read
  if[n = `UnExpr; :"(",(.aqc.gen.unOps e`op),"; ",(.aqc.gen.expr e`v),")"];
  if[n = `Id; :.aqc.gen.id e];
  if[n in `IntLit`FloatLit`StringLit`DateLit`TimestampLit`BooleanLit; :.aqc.gen.lit e];
  if[n = `FunCall; :.aqc.gen.funCall e];
  if[n = `ArrayIndex; :.aqc.gen.arrayIndex e];
  if[n = `Case; :.aqc.gen.caseExpr e];
  / WITH query column: DateInfo("startYear") is DateInfo`startYear
  if[n = `TableColumnValue; :(.aqc.gen.str e`t),.aqc.gen.sym e`c];
  if[n in `RowId`ColumnAccess`WildCard; :.aqc.gen.tableExpr e];
  '"codegen: not an expression: ",string n};

/ colLookup[name]
/   q code that looks up column name (Scala: getColLookup).
/     colLookup "price"   is "{x^.aq.cd x} `price"
.aqc.gen.colLookup:{[name] "{x^.aq.cd x} ",.aqc.gen.sym name};

/ id[e]
/   A name (Scala: genId). Inside a FUNCTION it is a variable, wrapped by
/   .aq.funEnlist; where names are variables (nameAsVar) it is the bare
/   name; everywhere else it is a column lookup.
/     id <price>   is "{x^.aq.cd x} `price"     (in a query)
/                     ".aq.funEnlist price"     (in a FUNCTION)
/                     "price"                   (nameAsVar)
.aqc.gen.id:{[e]
  name:.aqc.gen.str e`v;
  if[.aqc.gen.get `inUDF; :".aq.funEnlist ",name];
  if[.aqc.gen.get `nameAsVar; :name];
  .aqc.gen.colLookup name};

/ lit[e]
/   A literal (Scala: genLit).
/     1.5          is "1.5"         (Java's number format, see src/parse/ast.q)
/     "IBM"        is "(enlist `$\"IBM\")"   (strings become symbols)
/     '2020-01-02' is "\"D\"$\"2020-01-02\""
/     TRUE         is "1b"
/   SCALA QUIRK: the text of a string is not escaped, so a " inside it
/   ends the q string early.
/   Timestamps: the Scala parser makes them strings (so the jar writes a
/   symbol); our parser makes TimestampLit, which becomes "P"$"...".
/   FIXED (found in version 5): Scala writes a string as `$"IBM". The code
/   is part of a q parse tree, which is run with eval, and eval reads a
/   symbol atom as the NAME of a variable: WHERE ID = "IBM" looked for a
/   variable IBM and failed with 'IBM. A one-item list holding the symbol
/   is how a parse tree writes the constant `IBM, so we write
/   (enlist `$"IBM").
.aqc.gen.lit:{[e]
  n:e`node;
  v:e`v;
  if[n = `StringLit; :"(enlist `$\"",(.aqc.gen.str v),"\")"];
  if[n = `DateLit; :"\"D\"$\"",(.aqc.gen.str v),"\""];
  if[n = `TimestampLit; :"\"P\"$\"",(.aqc.gen.str v),"\""];
  if[n = `BooleanLit; :.aqc.gen.bool v];
  .aqc.ast.scalarText v};                       / IntLit, FloatLit

/ tableExpr[e]
/   ROWID, table.column and * (Scala: genTableExpr).
/     ROWID     is "`i"   (q's virtual row-number column)
/     t.price   is "{x^.aq.cd x} `t.price"
/     *         is "(.aq.wildCard aq__t0)"   (all columns of the current table)
.aqc.gen.tableExpr:{[e]
  n:.aqc.nodes.name e;
  if[n = `RowId; :"`i"];
  if[n = `ColumnAccess; :.aqc.gen.colLookup (.aqc.gen.str e`t),".",.aqc.gen.str e`c];
  "(.aq.wildCard ",(.aqc.gen.get `currTable),")"};

/ arrayIndex[e]
/   x[EVEN], x[ODD], x[EVERY n] (Scala: genArrayIndex).
/     a[EVERY 3]   is "(.aq.indexEveryN[3; ]; {x^.aq.cd x} `a)"
/   .aq.indexEveryN[3; ] is a q projection: the function with its first
/   argument fixed to 3, waiting for the second.
.aqc.gen.arrayIndex:{[e]
  ix:e`ix;
  op:$[`Even ~ ix; ".aq.indexEven";
    `Odd ~ ix; ".aq.indexOdd";
    ".aq.indexEveryN[",(string ix`v),"; ]"];    / Every(n)
  "(",op,"; ",(.aqc.gen.expr e`e),")"};

/ funCall[e]
/   A function call (Scala: genFunCall).
/     f(a, 2)           is "(f;{x^.aq.cd x} `a;2)"
/     COUNT(*)          is "(.aq.count;`i)"       (* becomes ROWID)
/     AND(a, b)         is "(.aq.and;(enlist;{x^.aq.cd x} `a;{x^.aq.cd x} `b))"
/     sum(a), grouped   is "(.aq.sum';{x^.aq.cd x} `a)"
/   After a GROUP BY each column is a list of groups, so the function is
/   applied to each group: q's each, written f'.
/   The second argument of IN gets enlist when it is a WITH query column,
/   so q's in sees one list, not a list of values.
.aqc.gen.funCall:{[e]
  f:e`f;
  args:e`args;
  isCount:.aqc.gen.sameName[f; "count"];
  isIn:.aqc.gen.sameName[f; "in"];
  codes:();
  k:0;
  while[k < count args;
    arg:args k;
    / COUNT(*) is COUNT(ROWID), as kdb+ counts with count i
    if[isCount and `WildCard ~ arg; arg:`RowId];
    code:.aqc.gen.expr arg;
    if[isIn and (k = 1) and `TableColumnValue ~ .aqc.nodes.name arg; code:"enlist ",code];
    codes,:enlist code;
    k+:1];
  argText:.aqc.gen.join[";"; codes];
  name:.aqc.gen.funName[f; count args];
  if[.aqc.gen.get `grouped; name,:"'"];
  if[(`$lower .aqc.gen.str f) in .aqc.gen.variadic; argText:.aqc.gen.addEnlist argText];
  "(",name,";",argText,")"};

/ addEnlist[code]
/   code (items separated by ";") made into a list that q builds when the
/   parse tree runs (Scala: addEnlist).
/     addEnlist "1;2"   is "(enlist;1;2)"
.aqc.gen.addEnlist:{[code] "(enlist;",code,")"};

/ caseExpr[e]
/   CASE [x] WHEN c THEN t ... [ELSE z] END (Scala: genCaseExpr), which
/   base.q's .aq.cond evaluates:
/     (.aq.cond; <x or ()>;(enlist;<WHEN 1>;<WHEN 2>...); <z or ()>)
/   each WHEN being (enlist;<c>; <t>).
/     CASE WHEN a > 1 THEN 1 ELSE 0 END   is
/     "(.aq.cond; ();(enlist;(enlist;(>; {x^.aq.cd x} `a; 1); 1)); 0)"
.aqc.gen.caseExpr:{[e]
  cond:$[`None ~ e`cond; "()"; .aqc.gen.expr (e`cond)`value];
  whens:();
  k:0;
  while[k < count e`when;
    w:(e`when) k;                               / IfThen(c, t)
    whens,:enlist .aqc.gen.addEnlist (.aqc.gen.expr w`c),"; ",.aqc.gen.expr w`t;
    k+:1];
  otherwise:$[`None ~ e`e; "()"; .aqc.gen.expr (e`e)`value];
  "(.aq.cond; ",cond,";",(.aqc.gen.addEnlist .aqc.gen.join[";"; whens]),"; ",otherwise,")"};


/ ---------------------------------------------------------------------------
/ Lists of expressions (used by the plan code)
/ ---------------------------------------------------------------------------

/ exprList[es; wrap]
/   The code of each expression in es, separated by ";" (Scala:
/   genExprList). With wrap, inside "(...)", and a single expression gets
/   enlist so that it is still a list. An empty es is "()".
/     exprList[(<a>; <b>); 1b]   is "({x^.aq.cd x} `a;{x^.aq.cd x} `b)"
/     exprList[enlist <a>; 1b]   is "enlist ({x^.aq.cd x} `a)"
/     exprList[(<a>; <b>); 0b]   is "{x^.aq.cd x} `a;{x^.aq.cd x} `b"
.aqc.gen.exprList:{[es;wrap]
  if[0 = count es; :"()"];
  codes:();
  k:0;
  while[k < count es;
    codes,:enlist .aqc.gen.expr es k;
    k+:1];
  text:.aqc.gen.join[";"; codes];
  if[not wrap; :text];
  $[1 = count es; "enlist (",text,")"; "(",text,")"]};

/ exprDict[pairs; keyCode]
/   A q dictionary from names to expressions, the form functional select
/   wants for its "by" and column arguments (Scala: genExprDict).
/   pairs:    list of (expression; name) pairs
/   keyCode:  function turning a name into q code for the key
/     exprDict[enlist (<a>; "x"); .aqc.gen.sym]   is
/       "(enlist[`x]!enlist {x^.aq.cd x} `a)"
/     exprDict[(<a>; "x"),(<b>; "y"); .aqc.gen.sym]   is
/       "((`x);(`y))!({x^.aq.cd x} `a;{x^.aq.cd x} `b)"
/   A * stands for all columns of the current table, (.aq.wildCard t),
/   which is already a dictionary; with other columns around it, each part
/   becomes its own dictionary and q's , joins them.
.aqc.gen.exprDict:{[pairs;keyCode]
  n:count pairs;
  isStar:{[pair] `WildCard ~ first pair};
  if[(n = 1) and isStar pairs 0; :.aqc.gen.tableExpr `WildCard];
  if[n = 1;
    p:pairs 0;
    :"(enlist[",(keyCode p 1),"]!enlist ",(.aqc.gen.expr p 0),")"];
  stars:();
  k:0;
  while[k < n; stars,:isStar pairs k; k+:1];
  / with a *: one dictionary per pair, joined with ","
  if[any stars;
    parts:();
    k:0;
    while[k < n;
      parts,:enlist .aqc.gen.exprDict[enlist pairs k; keyCode];
      k+:1];
    :.aqc.gen.join[","; parts]];
  keyCodes:();
  valueCodes:();
  k:0;
  while[k < n;
    keyCodes,:enlist "(",(keyCode pairs[k] 1),")";
    valueCodes,:enlist .aqc.gen.expr pairs[k] 0;
    k+:1];
  "(",(.aqc.gen.join[";"; keyCodes]),")!(",(.aqc.gen.join[";"; valueCodes]),")"};
