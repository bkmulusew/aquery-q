/ typecheck.q - the (soft) type checker (version 6).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/analysis/TypeChecker.scala.

/ The checker reads parse trees (the dictionaries of src/parse/ast.q) and
/ returns a list of errors (src/analysis/errors.q). It never changes the
/ tree. It is "soft": it only knows the types of literals, operators and
/ built-ins; columns and variables are `unknown, which matches anything.
/ So it catches mistakes like a + "x" or WHERE 1, and nothing that needs
/ the data.

/ Every function takes env, the function table for the program being
/ checked (.aqc.fn.env in functions.q): the built-ins plus the program's
/ UDFs. To check one expression on its own, use .aqc.fn.env ().

/ The expression checker returns a result: a dictionary
/   `tag`errors!(the expression's type; list of errors)
/ (Scala returns the pair (TypeTag, Seq[AnalysisError])).


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ result[tag; errs]
/   An expression's type and its errors.
.aqc.tc.result:{[tag;errs] `tag`errors!(tag; errs)};

/ pos[e]
/   Where node e starts, or an empty list. RowId and WildCard are plain
/   symbols with no position (see src/parse/ast.q).
.aqc.tc.pos:{[e] $[99h = type e; e`pos; `long$()]};   / 99h: a dictionary

/ concatAll[lists]
/   All the error lists in lists, joined in order (Scala: a ++ b ++ c).
.aqc.tc.concatAll:{[lists]
  out:();
  k:0;
  while[k < count lists;
    out:.aqc.ast.concat[out; lists k];
    k+:1];
  out};

/ The type of each kind of literal. Dates and timestamps count as numbers.
/ (Scala: checkLit)
.aqc.tc.litTags:`IntLit`FloatLit`StringLit`DateLit`BooleanLit`TimestampLit!
  `numeric`numeric`string`numeric`boolean`numeric;


/ ---------------------------------------------------------------------------
/ Expressions
/ ---------------------------------------------------------------------------

/ expr[env; e]
/   PUBLIC. The type of expression e and the errors inside it.
/     expr[.aqc.fn.env (); <2 * 3 / "a">]
/   is
/     `tag`errors!(`numeric; <one error: expected numeric found string at [1,9]>)
/   (Scala: checkExpr)
.aqc.tc.expr:{[env;e]
  n:.aqc.nodes.name e;
  if[n = `BinExpr; :.aqc.tc.binExpr[env; e]];
  if[n = `UnExpr; :.aqc.tc.unExpr[env; e]];
  if[n = `FunCall; :.aqc.tc.funCall[env; e]];
  / x[EVEN]: the type is not known (Scala TODO); only x is checked
  if[n = `ArrayIndex; :.aqc.tc.result[`unknown; (.aqc.tc.expr[env; e`e])`errors]];
  if[n = `Case; :.aqc.tc.caseExpr[env; e]];
  if[n in key .aqc.tc.litTags; :.aqc.tc.result[.aqc.tc.litTags n; ()]];
  if[n = `RowId; :.aqc.tc.result[`numeric; ()]];
  / Id, ColumnAccess (t.c), TableColumnValue (t("c")) and WildCard (*)
  .aqc.tc.result[`unknown; ()]};

/ checkTypeTag[env; expect; e]
/   The errors of e, plus one more if e's type does not fit expect (a
/   symbol list of allowed types). The new error names the first type in
/   expect and points at e.
/     checkTypeTag[env; .aqc.tc.bool; <1>]
/       is one error: expected boolean found numeric
/   (Scala: checkTypeTag)
.aqc.tc.checkTypeTag:{[env;expect;e]
  r:.aqc.tc.expr[env; e];
  if[.aqc.tc.consistent[r`tag; expect]; :r`errors];
  .aqc.ast.append[r`errors; .aqc.tc.err.typeError[first expect; r`tag; .aqc.tc.pos e]]};

/ binExpr[env; e]
/   An operator with two sides (Scala: checkBinExpr).
/     & |              both sides boolean; result boolean
/     < <= > >=        both sides numeric; result boolean
/     = !=             the right side has the left side's type; result boolean
/     + - * / ^        both sides numeric or boolean; result numeric
.aqc.tc.binExpr:{[env;e]
  op:e`op;
  if[op in `Land`Lor;
    :.aqc.tc.result[`boolean; .aqc.ast.concat[
      .aqc.tc.checkTypeTag[env; .aqc.tc.bool; e`l];
      .aqc.tc.checkTypeTag[env; .aqc.tc.bool; e`r]]]];
  if[op in `Lt`Le`Gt`Ge;
    :.aqc.tc.result[`boolean; .aqc.ast.concat[
      .aqc.tc.checkTypeTag[env; .aqc.tc.num; e`l];
      .aqc.tc.checkTypeTag[env; .aqc.tc.num; e`r]]]];
  if[op in `Eq`Neq;
    left:.aqc.tc.expr[env; e`l];
    :.aqc.tc.result[`boolean; .aqc.ast.concat[
      left`errors;
      .aqc.tc.checkTypeTag[env; enlist left`tag; e`r]]]];
  / Plus Minus Times Div Exp
  .aqc.tc.result[`numeric; .aqc.ast.concat[
    .aqc.tc.checkTypeTag[env; .aqc.tc.numAndBool; e`l];
    .aqc.tc.checkTypeTag[env; .aqc.tc.numAndBool; e`r]]]};

/ unExpr[env; e]
/   NOT x (its argument boolean) or -x (numeric). The result has that type
/   even when the argument is wrong. (Scala: checkUnaryExpr)
.aqc.tc.unExpr:{[env;e]
  $[`Not = e`op;
    .aqc.tc.result[`boolean; .aqc.tc.checkTypeTag[env; .aqc.tc.bool; e`v]];
    .aqc.tc.result[`numeric; .aqc.tc.checkTypeTag[env; .aqc.tc.num; e`v]]]};

/ funCall[env; e]
/   A function call f(a, b, ...) (Scala: checkCallExpr).
/   - f in env: the argument types must fit f's signature (for a UDF: the
/     number of arguments must match). The result is f's result type; when
/     the call does not fit, `unknown and a BadCall error before the
/     arguments' own errors.
/   - f unknown (a q function, say): `unknown, only the arguments checked.
.aqc.tc.funCall:{[env;e]
  args:e`args;
  argTags:`symbol$();
  argErrors:();
  k:0;
  while[k < count args;
    r:.aqc.tc.expr[env; args k];
    argTags,:r`tag;
    argErrors:.aqc.ast.concat[argErrors; r`errors];
    k+:1];
  f:`$.aqc.tc.err.str e`f;
  if[not .aqc.fn.known[env; f]; :.aqc.tc.result[`unknown; argErrors]];
  ret:.aqc.fn.resultType[env; f; argTags];
  if[`bad = ret;
    badCall:.aqc.tc.err.badCall[e`f; .aqc.tc.pos e];
    :.aqc.tc.result[`unknown; .aqc.ast.concat[.aqc.nodes.one badCall; argErrors]]];
  .aqc.tc.result[ret; argErrors]};

/ caseExpr[env; c]
/   CASE [value] WHEN w1 THEN t1 WHEN w2 THEN t2 ... [ELSE z] END
/   (Scala: checkCaseExpr). The rules:
/   - with a value after CASE, every WHEN has the value's type; without
/     one, every WHEN is boolean
/   - the first THEN gives the type of the whole CASE; the other THENs and
/     the ELSE must have that type
/   Errors in this order: the value's, the WHENs', the THENs', the ELSE's.
/   DIVERGENCE (tests/analysis/divergences.txt): Scala checks the second
/   and later WHEN branches as whole IfThen nodes instead of their THEN
/   expressions, which crashes (scala.MatchError) on any CASE with two or
/   more WHENs. Here they are checked as Scala clearly meant: their THENs.
.aqc.tc.caseExpr:{[env;c]
  whens:c`when;
  / the type every WHEN must have
  condTag:`boolean;
  condErrors:();
  if[not `None ~ c`cond;
    r:.aqc.tc.expr[env; c[`cond]`value];
    condTag:r`tag;
    condErrors:r`errors];
  ifErrors:();
  k:0;
  while[k < count whens;
    ifErrors:.aqc.ast.concat[ifErrors; .aqc.tc.checkTypeTag[env; enlist condTag; whens[k]`c]];
    k+:1];
  / the type of the whole CASE, from the first THEN. (The parser always
  / gives a CASE at least one WHEN; Scala reports a missing one anyway.)
  caseTag:`unknown;
  thenErrors:.aqc.nodes.one .aqc.tc.err.typeError[`boolean; `unit; .aqc.tc.pos c];
  if[0 < count whens;
    r:.aqc.tc.expr[env; whens[0]`t];
    caseTag:r`tag;
    thenErrors:r`errors;
    k:1;
    while[k < count whens;
      thenErrors:.aqc.ast.concat[thenErrors; .aqc.tc.checkTypeTag[env; enlist caseTag; whens[k]`t]];
      k+:1]];
  elseErrors:();
  if[not `None ~ c`e; elseErrors:.aqc.tc.checkTypeTag[env; enlist caseTag; c[`e]`value]];
  .aqc.tc.result[caseTag; .aqc.tc.concatAll (condErrors; ifErrors; thenErrors; elseErrors)]};

/ prohibited[e]
/   PUBLIC. Errors for the parts of e that only make sense inside a query:
/   *, ROWID and t.c. Used for UDF bodies and INSERT ... VALUES.
/     prohibited <t.c + 1>   is one error: Illegal expression in t.c at [1,1]
/   (Scala: checkProhibitedExpr)
/   DIVERGENCE (tests/analysis/divergences.txt): * and ROWID have no
/   position in the q tree, so their error gets the position of the
/   nearest enclosing node that has one. (Scala's * and ROWID objects are
/   shared by the whole program and keep the position of the first one
/   ever parsed, so Scala's position is not reliable either.)
.aqc.tc.prohibited:{[e] .aqc.tc.prohibitedIn[e; `long$()]};

/ prohibitedIn[e; outerPos]
/   prohibited, where outerPos is the position of the closest enclosing
/   node that has one.
.aqc.tc.prohibitedIn:{[e;outerPos]
  here:.aqc.tc.pos e;
  if[0 = count here; here:outerPos];
  if[(.aqc.nodes.name e) in `WildCard`ColumnAccess`RowId;
    :.aqc.nodes.one .aqc.tc.err.illegalExpr[.aqc.dot.label[e; 1]; here]];
  kids:.aqc.nodes.exprChildren e;
  out:();
  k:0;
  while[k < count kids;
    out:.aqc.ast.concat[out; .aqc.tc.prohibitedIn[kids k; here]];
    k+:1];
  out};


/ ---------------------------------------------------------------------------
/ Plans (the relational algebra of a query)
/ ---------------------------------------------------------------------------

/ checkEach[env; expect; es]
/   checkTypeTag for every expression in es, errors joined in order.
/   (Scala: es.flatMap(checkTypeTag(expect, _)))
.aqc.tc.checkEach:{[env;expect;es]
  out:();
  k:0;
  while[k < count es;
    out:.aqc.ast.concat[out; .aqc.tc.checkTypeTag[env; expect; es k]];
    k+:1];
  out};

/ errorsOfEach[env; es]
/   The errors inside every expression in es, whatever their types.
/   (Scala: es.flatMap(checkExpr(_)._2))
.aqc.tc.errorsOfEach:{[env;es]
  out:();
  k:0;
  while[k < count es;
    out:.aqc.ast.concat[out; (.aqc.tc.expr[env; es k])`errors];
    k+:1];
  out};

/ prohibitedInEach[es]
/   prohibited for every expression in es.
.aqc.tc.prohibitedInEach:{[es]
  out:();
  k:0;
  while[k < count es;
    out:.aqc.ast.concat[out; .aqc.tc.prohibited es k];
    k+:1];
  out};

/ sortExprs[es]
/   ASSUMING / ORDER BY may only name plain columns: c or t.c. One
/   IllegalExpr error for every other expression in es.
/     sortExprs (<a>; <a + 1>)   is one error: Illegal expression in a+1
/   (Scala: checkSortExpr)
.aqc.tc.sortExprs:{[es]
  out:();
  k:0;
  while[k < count es;
    e:es k;
    if[not (.aqc.nodes.name e) in `Id`ColumnAccess;
      out:.aqc.ast.append[out; .aqc.tc.err.illegalExpr[.aqc.dot.label[e; 1]; .aqc.tc.pos e]]];
    k+:1];
  out};

/ planExprErrors[env; r]
/   The errors in the expressions of plan r and of every plan below it
/   (Scala: checkExprInRelAlg). What each node checks:
/     Filter (WHERE)       every condition is boolean
/     GroupBy              HAVING conditions are boolean; then the errors
/                          inside the GROUP BY and HAVING expressions.
/                          SCALA QUIRK, copied: HAVING is checked twice, so
/                          an error inside a HAVING condition appears twice.
/     Join                 every condition is boolean
/     SortBy (ASSUMING)    plain columns only (sortExprs); nothing else
/     Project and others   the errors inside the expressions
.aqc.tc.planExprErrors:{[env;r]
  n:.aqc.nodes.name r;
  es:.aqc.nodes.planExprs r;
  own:$[n = `Filter; .aqc.tc.checkEach[env; .aqc.tc.bool; es];
    n = `GroupBy; .aqc.ast.concat[.aqc.tc.checkEach[env; .aqc.tc.bool; r`having]; .aqc.tc.errorsOfEach[env; es]];
    n = `Join; .aqc.tc.checkEach[env; .aqc.tc.bool; es];
    n = `SortBy; .aqc.tc.sortExprs es;
    .aqc.tc.errorsOfEach[env; es]];
  kids:.aqc.nodes.planChildren r;
  k:0;
  while[k < count kids;
    own:.aqc.ast.concat[own; .aqc.tc.planExprErrors[env; kids k]];
    k+:1];
  own};

/ tablesIn[r]
/   Every Table node in plan r, top to bottom, left to right.
/   (Scala: allTablesInQuery)
.aqc.tc.tablesIn:{[r]
  if[`Table = .aqc.nodes.name r; :.aqc.nodes.one r];
  kids:.aqc.nodes.planChildren r;
  out:();
  k:0;
  while[k < count kids;
    out:.aqc.ast.concat[out; .aqc.tc.tablesIn kids k];
    k+:1];
  out};

/ aliasOf[t]
/   The correlation name of Table node t as a symbol (FROM t AS x gives
/   `x), or ` (the empty symbol) when it has none.
.aqc.tc.aliasOf:{[t] $[`None ~ t`alias; `; `$.aqc.tc.err.str t[`alias]`value]};

/ refName[t]
/   The name a query uses for table t: its correlation name if it has one,
/   otherwise its own name. FROM t x can only be referred to as x.
.aqc.tc.refName:{[t] $[`None ~ t`alias; `$.aqc.tc.err.str t`n; .aqc.tc.aliasOf t]};

/ fullName[t]
/   Table t as the duplicate-table message prints it: "t" or "t as x".
.aqc.tc.fullName:{[t]
  $[`None ~ t`alias; .aqc.tc.err.str t`n; (.aqc.tc.err.str t`n)," as ",.aqc.tc.err.str t[`alias]`value]};

/ duplicates[ts; groupKeys]
/   One DuplicateTableName error for every group of tables in ts that share
/   a key; groupKeys holds one key per table. The error names the group's first
/   two tables. (Scala: checkDuplicates)
/   A table is the second of its group when exactly one table before it
/   has the same key; that table is the first.
.aqc.tc.duplicates:{[ts;groupKeys]
  out:();
  i:0;
  while[i < count ts;
    earlier:where (i # groupKeys) ~\: groupKeys i;    / ~\: compares key i with each earlier key
    if[1 = count earlier;
      t1:ts first earlier;
      t2:ts i;
      out:.aqc.ast.append[out;
        .aqc.tc.err.duplicateTable[.aqc.tc.fullName t1; .aqc.tc.fullName t2; .aqc.tc.pos t1; .aqc.tc.pos t2]]];
    i+:1];
  out};

/ colAccessesIn[e]
/   Every t.c (ColumnAccess node) inside expression e.
.aqc.tc.colAccessesIn:{[e]
  if[`ColumnAccess = .aqc.nodes.name e; :.aqc.nodes.one e];
  kids:.aqc.nodes.exprChildren e;
  out:();
  k:0;
  while[k < count kids;
    out:.aqc.ast.concat[out; .aqc.tc.colAccessesIn kids k];
    k+:1];
  out};

/ distinctColAccesses[es]
/   The t.c nodes inside the expressions es, each t.c only once (the first
/   one found, with its position). (Scala: es.flatMap(allColAccesses).toSet;
/   Scala's set ignores positions when it compares two t.c nodes.)
.aqc.tc.distinctColAccesses:{[es]
  out:();
  seen:();       / the (t; c) pairs already in out
  k:0;
  while[k < count es;
    found:.aqc.tc.colAccessesIn es k;
    j:0;
    while[j < count found;
      ca:found j;
      tc:(`$.aqc.tc.err.str ca`t; `$.aqc.tc.err.str ca`c);
      if[not any seen ~\: tc;
        seen,:enlist tc;
        out:.aqc.ast.append[out; ca]];
      j+:1];
    k+:1];
  out};

/ checkColAccesses[names; cas]
/   An error for every t.c in cas whose t is not usable: Ambiguous when
/   two tables in names are called t, Unknown when none is.
/   names: symbols, the names the query's tables can be referred to by
/   (Scala: checkColAccesses)
.aqc.tc.checkColAccesses:{[names;cas]
  out:();
  k:0;
  while[k < count cas;
    ca:cas k;
    t:`$.aqc.tc.err.str ca`t;
    text:(.aqc.tc.err.str ca`t),".",.aqc.tc.err.str ca`c;
    $[1 < sum names = t;
      out:.aqc.ast.append[out; .aqc.tc.err.ambigColAccess[text; .aqc.tc.pos ca]];
      not t in names;
      out:.aqc.ast.append[out; .aqc.tc.err.unknownCorrName[text; .aqc.tc.pos ca]];
      ::];
    k+:1];
  out};

/ relAlg[env; r; extraNames]
/   PUBLIC. The errors in one query plan r (Scala: checkRelAlg):
/   - errors in its expressions (planExprErrors)
/   - two tables with the same correlation name
/   - the same table twice (same name and same correlation name)
/   - t.c where t is not a table of the query, or is ambiguous
/   extraNames: symbols, more names t.c may use (the REFERENCING names
/   inside a trigger; () otherwise).
/   SCALA QUIRK, copied: t.c is only looked for in the top plan node and
/   its direct children (Scala: (r +: r.children)), so a t.c deeper down,
/   e.g. in a WHERE under a GROUP BY, is never reported.
.aqc.tc.relAlg:{[env;r;extraNames]
  exprErrors:.aqc.tc.planExprErrors[env; r];
  fromTables:.aqc.tc.tablesIn r;   / (not "tables": a q built-in)
  / keep only the tables that have a correlation name
  aliased:();
  k:0;
  while[k < count fromTables;
    if[not `None ~ fromTables[k]`alias; aliased:.aqc.ast.append[aliased; fromTables k]];
    k+:1];
  dupAliasErrors:.aqc.tc.duplicates[aliased; .aqc.tc.aliasOf each aliased];
  / a table's key is its name and its correlation name (` if none)
  tableKeys:{(`$.aqc.tc.err.str x`n; .aqc.tc.aliasOf x)} each fromTables;
  dupTableErrors:.aqc.tc.duplicates[fromTables; tableKeys];
  names:(.aqc.tc.refName each fromTables),extraNames;
  / the expressions of r and of its direct children
  nodes:.aqc.ast.concat[.aqc.nodes.one r; .aqc.nodes.planChildren r];
  es:();
  k:0;
  while[k < count nodes;
    es:.aqc.ast.concat[es; .aqc.nodes.planExprs nodes k];
    k+:1];
  colErrors:.aqc.tc.checkColAccesses[names; .aqc.tc.distinctColAccesses es];
  .aqc.tc.concatAll (exprErrors; dupAliasErrors; dupTableErrors; colErrors)};

/ query[env; q; extraNames]
/   The errors in a query: each WITH local query, then the main one.
/   (Scala: checkQuery)
.aqc.tc.query:{[env;q;extraNames]
  locals:q`local;
  out:();
  k:0;
  while[k < count locals;
    out:.aqc.ast.concat[out; .aqc.tc.relAlg[env; locals[k]`_3; extraNames]];   / _3: the plan of (name; columns; plan)
    k+:1];
  .aqc.ast.concat[out; .aqc.tc.relAlg[env; q`main; extraNames]]};


/ ---------------------------------------------------------------------------
/ Statements
/ ---------------------------------------------------------------------------

/ rightItems[x]
/   The list inside Right(list), or () for Left(...).
.aqc.tc.rightItems:{[x] $[`Right = x`node; x`value; ()]};

/ update[env; u; extraNames]
/   UPDATE t SET c = e, ... [ASSUMING ...] [WHERE ...] [GROUP BY ...]
/   [HAVING ...] (Scala: checkModificationQuery). The SET values are
/   checked, ASSUMING must name plain columns, WHERE and HAVING are
/   boolean, and t.c may only name the updated table.
.aqc.tc.update:{[env;u;extraNames]
  setValues:.aqc.nodes.fieldOfEach[u`assigns; `_2];
  sortBy:.aqc.nodes.fieldOfEach[u`order; `_2];
  allExprs:.aqc.tc.concatAll (setValues; sortBy; u`where; u`groupby; u`having);
  names:(enlist `$.aqc.tc.err.str u`t),extraNames;
  .aqc.tc.concatAll (
    .aqc.tc.errorsOfEach[env; setValues];
    .aqc.tc.sortExprs sortBy;
    .aqc.tc.checkEach[env; .aqc.tc.bool; u`where];
    .aqc.tc.errorsOfEach[env; u`groupby];
    .aqc.tc.checkEach[env; .aqc.tc.bool; u`having];
    .aqc.tc.checkColAccesses[names; .aqc.tc.distinctColAccesses allExprs])};

/ delete[env; d; extraNames]
/   DELETE FROM t [ASSUMING ...] WHERE ... [GROUP BY ...] [HAVING ...], or
/   DELETE c1, c2 FROM t. Like update. (Scala: checkModificationQuery)
.aqc.tc.delete:{[env;d;extraNames]
  conds:.aqc.tc.rightItems d`del;
  sortBy:.aqc.nodes.fieldOfEach[d`order; `_2];
  allExprs:.aqc.tc.concatAll (conds; sortBy; d`groupby; d`having);
  names:(enlist `$.aqc.tc.err.str d`t),extraNames;
  .aqc.tc.concatAll (
    .aqc.tc.checkEach[env; .aqc.tc.bool; conds];
    .aqc.tc.sortExprs sortBy;
    .aqc.tc.errorsOfEach[env; d`groupby];
    .aqc.tc.checkEach[env; .aqc.tc.bool; d`having];
    .aqc.tc.checkColAccesses[names; .aqc.tc.distinctColAccesses allExprs])};

/ insert[env; i; extraNames]
/   INSERT INTO t [ASSUMING ...] VALUES (...) or INSERT INTO t ... SELECT.
/   VALUES may not use *, ROWID or t.c. (Scala: checkTableModification)
.aqc.tc.insert:{[env;i;extraNames]
  sortErrors:.aqc.tc.sortExprs .aqc.nodes.fieldOfEach[i`order; `_2];
  src:i`src;
  if[`Right = src`node; :.aqc.ast.concat[.aqc.tc.query[env; src`value; extraNames]; sortErrors]];
  rowValues:src`value;
  .aqc.tc.concatAll (.aqc.tc.errorsOfEach[env; rowValues]; sortErrors; .aqc.tc.prohibitedInEach rowValues)};

/ udf[env; u]
/   FUNCTION f(...) { ... }: every line of the body is checked, and may not
/   use *, ROWID or t.c. (Scala: checkUDF)
.aqc.tc.udf:{[env;u]
  lines:u`cs;
  out:();
  k:0;
  while[k < count lines;
    line:lines k;
    / Left(Assign(name, e)) for "name := e", Right(e) for a plain e
    e:$[`Left = line`node; line[`value]`e; line`value];
    out:.aqc.tc.concatAll (out; (.aqc.tc.expr[env; e])`errors; .aqc.tc.prohibited e);
    k+:1];
  out};

/ statement[env; s; extraNames]
/   PUBLIC. The errors in one top-level statement (Scala: checkTopLevel).
/   DIVERGENCE (tests/analysis/divergences.txt): Scala has no case for
/   LOAD, SAVE, CREATE TRIGGER and DROP TRIGGER and crashes on them. Here
/   LOAD, SAVE and DROP TRIGGER have no errors, and a trigger's statement
/   (after DO) is checked, with its REFERENCING names usable as t in t.c.
.aqc.tc.statement:{[env;s;extraNames]
  n:.aqc.nodes.name s;
  if[n = `Query; :.aqc.tc.query[env; s; extraNames]];
  if[n = `Update; :.aqc.tc.update[env; s; extraNames]];
  if[n = `Delete; :.aqc.tc.delete[env; s; extraNames]];
  if[n = `Create; :$[`Right = s[`source]`node; .aqc.tc.query[env; s[`source]`value; extraNames]; ()]];
  if[n = `Insert; :.aqc.tc.insert[env; s; extraNames]];
  if[n = `UDF; :.aqc.tc.udf[env; s]];
  if[n = `Trigger;
    refNames:`$.aqc.tc.err.str each .aqc.nodes.fieldOfEach[s`refs; `alias];
    :.aqc.tc.statement[env; s`body; extraNames,refNames]];
  / VerbatimCode (q code is not checked), Load, Save, DropTrigger
  ()};


/ ---------------------------------------------------------------------------
/ Whole programs
/ ---------------------------------------------------------------------------

/ program[prog]
/   PUBLIC. The errors in a parsed program, sorted by position (line, then
/   column; errors at the same position keep their order). The checker
/   knows every UDF the program defines. (Scala: TypeChecker(prog).typeCheck
/   and the sortBy in Aquery.scala)
/   prog: list of top-level nodes (what .aqc.gen.parseText returns)
.aqc.tc.program:{[prog]
  env:.aqc.fn.env prog;
  errs:();
  k:0;
  while[k < count prog;
    errs:.aqc.ast.concat[errs; .aqc.tc.statement[env; prog k; `symbol$()]];
    k+:1];
  if[0 = count errs; :()];
  / one number per error that sorts like (line, column): line * 1000000 +
  / column; no position counts as line 0, column 0
  sortKeys:{[e] p:e`pos; $[0 = count p; 0; (1000000 * p 0) + p 1]} each errs;
  errs iasc sortKeys};          / iasc keeps equal keys in their order

/ messages[text]
/   PUBLIC. Type check AQuery text: one line per error, as aquery.jar -tc
/   prints them. Signals an error if the text does not parse.
/     messages "SELECT a FROM t WHERE 1"
/   is
/     enlist "Type Error: expected boolean found numeric at [1,23]"
.aqc.tc.messages:{[text] .aqc.tc.err.message each .aqc.tc.program .aqc.gen.parseText text};

/ typecheck[text]
/   PUBLIC. Type check AQuery text without running it: one line per error,
/   as aquery.jar -tc prints them, or an empty list if there are none.
/     .aqc.typecheck "SELECT a FROM t WHERE 1"
/   is
/     enlist "Type Error: expected boolean found numeric at [1,23]"
.aqc.typecheck:{[text] .aqc.tc.messages text};
