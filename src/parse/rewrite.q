/ rewrite.q - the last step of parsing a program: string constants in WITH
/ queries.

/ Ported from rewriteLocalStringConstants in
/ aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala.
/ Scala runs it on the list of statements right after `program` parses, so
/ its result is what the golden files hold. It only touches top-level
/ queries that have WITH local queries, and does two things in them:

/ 1. A string constant in a SELECT list becomes a call to a small q helper
/    that repeats the constant as a symbol, once per row:
/        WITH x AS (...) SELECT a, "weekly" FROM x
/    gets  SELECT a, aqConstWeekly(a) FROM x  and the program gets one extra
/    statement at the front, VerbatimCode with the helper definitions:
/        aqConstWeekly:{(count x)#`weekly};
/    (the helper's argument is the first SELECT expression that is not a
/    string, so it has one value per row). A SELECT list with only strings
/    is left alone.
/ 2. x("c"), where x is the name of a local query, becomes
/    TableColumnValue(x, c): column c of local query x.

/ Scala builds a new node for everything on the way down to a change, and a
/ new node has no position. So after the rewrite, those nodes print with no
/ "@line:col" in the golden files, while the leaves that were not rebuilt
/ (Id, literals, Table, ...) keep theirs. The functions below build every
/ node they return with the .aqc.ast constructors, which start with no
/ position, so they do the same.

/ DIVERGENCE: Scala's lexer makes a timestamp literal a string, so Scala
/ would turn a timestamp in such a SELECT list into a helper too. Here it
/ is a TimestampLit and is left alone. No test input does this.


/ The string constants found so far, in the order found, without repeats
/ (Scala: a LinkedHashSet). Reset by rewriteProgram.
.aqc.rewrite.helpers:();


/ ---------------------------------------------------------------------------
/ The whole program
/ ---------------------------------------------------------------------------

/ rewriteProgram[prog]
/   PUBLIC. prog is the list of statements from .aqc.parse.program; the
/   result is the rewritten list, with VerbatimCode for the helpers first
/   if any string constant was rewritten.
.aqc.rewrite.rewriteProgram:{[prog]
  .aqc.rewrite.helpers:();
  out:.aqc.rewrite.topLevel each prog;
  if[0 = count .aqc.rewrite.helpers; :out];
  defs:.aqc.rewrite.helperDef each .aqc.rewrite.helpers;
  code:"\n" sv defs;              / sv joins the strings with "\n" between
  .aqc.ast.concat[.aqc.ast.append[();.aqc.ast.verbatimCode code];out]};

/ topLevel[s]
/   A query with WITH local queries, rewritten; any other statement as is.
.aqc.rewrite.topLevel:{[s]
  if[not .aqc.rewrite.isA[`Query;s]; :s];
  if[0 = count s`local; :s];
  / the local query names: the first part of each Tuple(name, cols, query)
  names:.aqc.rewrite.part[;0] each s`local;   / part[;0] fixes k at 0
  locals:.aqc.rewrite.localQuery[names] each s`local;
  .aqc.ast.query[locals;.aqc.rewrite.relAlg[names;s`main]]};

/ localQuery[names; t]: Tuple(name, cols, query) with the query rewritten
.aqc.rewrite.localQuery:{[names;t]
  parts:(.aqc.rewrite.part[t;0];.aqc.rewrite.part[t;1];.aqc.rewrite.relAlg[names;.aqc.rewrite.part[t;2]]);
  .aqc.ast.tuple parts};


/ ---------------------------------------------------------------------------
/ Helper names and definitions
/ ---------------------------------------------------------------------------

/ helperName[s]
/   The q helper's name for string constant s: "aqConst", then each run of
/   letters and digits in s, lower case with the first letter capitalised.
/     helperName "weekly"        is "aqConstWeekly"
/     helperName "hello, WORLD"  is "aqConstHelloWorld"
/     helperName "--"            is "aqConstSymbol"   (no letters or digits)
.aqc.rewrite.helperName:{[s]
  txt:lower (),s;                 / (), makes a 1-character s a string
  / every character that is not a letter or digit becomes a space ...
  txt[where not txt in .Q.a,.Q.A,.Q.n]:" ";
  / ... so splitting at spaces gives the runs (and some empty strings)
  words:(" " vs txt) except enlist "";
  if[0 = count words; :"aqConstSymbol"];
  "aqConst",raze .aqc.rewrite.capitalize each words};

/ capitalize[w]: w with its first character in upper case ("week" -> "Week")
.aqc.rewrite.capitalize:{[w]
  w[0]:upper w 0;
  w};

/ helperDef[s]
/   The q definition of the helper for s: it takes any list x and returns
/   the symbol `s repeated count x times. Backquotes in s are dropped.
/     helperDef "weekly"   is   "aqConstWeekly:{(count x)#`weekly};"
.aqc.rewrite.helperDef:{[s]
  (.aqc.rewrite.helperName s),":{(count x)#`",(((),s) except "`"),"};"};

/ addHelper[s]: remember string constant s (once)
.aqc.rewrite.addHelper:{[s]
  if[not any .aqc.rewrite.helpers ~\: (),s;
    .aqc.rewrite.helpers,:enlist (),s]};


/ ---------------------------------------------------------------------------
/ Queries
/ ---------------------------------------------------------------------------

/ relAlg[names; r]
/   Query part r with every expression inside rewritten (see expr) and every
/   SELECT list's string constants replaced (see project). names are the
/   local query names.
.aqc.rewrite.relAlg:{[names;r]
  ex:.aqc.rewrite.expr[names];          / ex is a rule: expr with names fixed
  rel:.aqc.rewrite.relAlg[names];
  if[.aqc.rewrite.isA[`Project;r];
    ps:.aqc.rewrite.firstOfPair[ex] each r`ps;
    :.aqc.rewrite.project .aqc.ast.project[rel r`t;ps]];
  if[.aqc.rewrite.isA[`Filter;r];
    :.aqc.ast.filter[rel r`t;ex each r`fs]];
  if[.aqc.rewrite.isA[`GroupBy;r];
    gs:.aqc.rewrite.firstOfPair[ex] each r`gs;
    :.aqc.ast.groupBy[rel r`t;gs;ex each r`having]];
  if[.aqc.rewrite.isA[`SortBy;r];
    :.aqc.ast.sortBy[rel r`t;.aqc.rewrite.secondOfPair[ex] each r`os]];
  if[.aqc.rewrite.isA[`TopApply;r];
    :.aqc.ast.topApply[r`f;rel r`t]];
  if[.aqc.rewrite.isA[`BottomApply;r];
    :.aqc.ast.bottomApply[r`f;ex each r`args]];
  if[.aqc.rewrite.isA[`Join;r];
    :.aqc.ast.join[r`jt;rel r`l;rel r`r;ex each r`cond]];
  r};                             / Table: nothing to rewrite

/ project[p]
/   Project p with each string constant in its SELECT list replaced by a
/   helper call, FunCall(helperName s, List(arg)), where arg is the first
/   SELECT expression that is not a string constant. If there is none, p
/   is returned as it is.
.aqc.rewrite.project:{[p]
  ps:p`ps;
  strings:.aqc.rewrite.isStringPair each ps;      / e.g. 0110b
  if[all strings; :p];                            / also when ps is empty
  / arg: the first SELECT expression that is not a string
  arg:.aqc.rewrite.part[ps first where not strings;0];
  .aqc.ast.project[p`t;.aqc.rewrite.constantToHelper[arg] each ps]};

/ isStringPair[pair]: is Tuple(expr, alias) from a SELECT list a string?
.aqc.rewrite.isStringPair:{[pair] .aqc.rewrite.isA[`StringLit;.aqc.rewrite.part[pair;0]]};

/ constantToHelper[arg; pair]
/   Tuple(expr, alias) from a SELECT list: if expr is a string constant s,
/   Tuple(FunCall(helperName s, List(arg)), alias); otherwise pair itself.
.aqc.rewrite.constantToHelper:{[arg;pair]
  e:.aqc.rewrite.part[pair;0];
  if[not .aqc.rewrite.isA[`StringLit;e]; :pair];
  .aqc.rewrite.addHelper e`v;
  call:.aqc.ast.funCall[.aqc.rewrite.helperName e`v;.aqc.ast.append[();arg]];
  .aqc.ast.tuple (call;.aqc.rewrite.part[pair;1])};


/ ---------------------------------------------------------------------------
/ Expressions
/ ---------------------------------------------------------------------------

/ expr[names; e]
/   Expression e with x("c") calls to local queries replaced by
/   TableColumnValue(x, c), looking inside function calls, operators,
/   indexing and CASE. Anything else (Id, literals, ...) is returned as is.
.aqc.rewrite.expr:{[names;e]
  ex:.aqc.rewrite.expr[names];
  if[.aqc.rewrite.isA[`FunCall;e];
    args:e`args;
    if[(1 = count args) and (any names ~\: e`f) and .aqc.rewrite.isA[`StringLit;args 0];
      :.aqc.ast.tableColumnValue[e`f;(args 0)`v]];
    :.aqc.ast.funCall[e`f;ex each args]];
  if[.aqc.rewrite.isA[`BinExpr;e];
    :.aqc.ast.binExpr[e`op;ex e`l;ex e`r]];
  if[.aqc.rewrite.isA[`UnExpr;e];
    :.aqc.ast.unExpr[e`op;ex e`v]];
  if[.aqc.rewrite.isA[`ArrayIndex;e];
    :.aqc.ast.arrayIndex[ex e`e;e`ix]];
  if[.aqc.rewrite.isA[`IfThen;e];
    :.aqc.ast.ifThen[ex e`c;ex e`t]];
  if[.aqc.rewrite.isA[`Case;e];
    :.aqc.ast.case[.aqc.rewrite.mapOption[ex;e`cond];ex each e`when;.aqc.rewrite.mapOption[ex;e`e]]];
  e};


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ The lists built here with each may come back as tables (see "A Q TRAP"
/ in ast.q); everything that reads them handles that.

/ isA[name; x]: is x a node (or container) of Scala class name?
.aqc.rewrite.isA:{[name;x] $[.aqc.ast.isNode x; name = x`node; 0b]};

/ mapOption[f; o]: `None stays `None; Some(x) becomes Some(f x)
.aqc.rewrite.mapOption:{[f;o]
  $[.aqc.rewrite.isA[`Some;o]; .aqc.ast.some f o`value; o]};

/ part[t; k]: part k of Tuple t, counting from 0 (Scala: t._1 is part 0)
.aqc.rewrite.part:{[t;k] t (.aqc.ast.fields t) k};

/ firstOfPair[f; t]: Tuple(a, b) -> Tuple(f a, b)
.aqc.rewrite.firstOfPair:{[f;t]
  .aqc.ast.tuple (f .aqc.rewrite.part[t;0];.aqc.rewrite.part[t;1])};

/ secondOfPair[f; t]: Tuple(a, b) -> Tuple(a, f b)
.aqc.rewrite.secondOfPair:{[f;t]
  .aqc.ast.tuple (.aqc.rewrite.part[t;0];f .aqc.rewrite.part[t;1])};
