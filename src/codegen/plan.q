/ plan.q - q code for query plans and whole queries.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/codegen/
/ KdbGenerator.scala: genRelAlg and the functions it calls (genTable,
/ genFilter, genGroupBy, genProject, genTopApply, genSortBy, genColSortBy,
/ genOrderTuples, genJoin, genBottomApply), addColNames, and the query
/ functions genLocalQuery, genPlan, genQuery.
/ As in expr.q, Scala's odd corners are copied on purpose (SCALA QUIRK)
/ and its bugs are fixed (FIXED).

/ WHAT THE CODE LOOKS LIKE
/ A plan is a chain of steps, innermost first: FROM, then WHERE, GROUP BY,
/ SELECT, ... Each step becomes one line that replaces a temporary table
/ aq__tN with the step's result, mostly with q's functional select
/ ?[table; where; by; columns]:
/     SELECT a FROM t WHERE a > 1
/   becomes
/      aq__t0:.aq.initTable[t;"t";0b];
/      aq__t0:?[aq__t0;enlist ((>; {x^.aq.cd x} `a; 1));0b;()];
/      aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];
/ Every line starts with a space. The state field currTable names the
/ table the next step reads (see src/codegen/state.q).

/ Plans change the state (new table names, grouped, ...), so the order of
/ statements below matters: each function does its steps one statement at
/ a time, in Scala's order.


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ select[t; w; b; p]
/   q's functional select ?[t;w;b;p] as text (Scala: kdbSelect). An empty
/   string stands for "not given" and gets q's default: () for w and p, 0b
/   for b.
/     select["aq__t0"; ""; ""; ""]   is "?[aq__t0;();0b;()]"
.aqc.gen.select:{[t;w;b;p]
  w:$[0 = count w; "()"; w];
  b:$[0 = count b; "0b"; b];
  p:$[0 = count p; "()"; p];
  "?[",t,";",w,";",b,";",p,"]"};

/ step[before; t; code]
/   The code before this step, then a new line " t:code;".
/     step[" aq__t0:x;"; "aq__t0"; "y"]   is " aq__t0:x;\n aq__t0:y;"
.aqc.gen.step:{[before;t;code] before,"\n ",t,":",code,";"};

/ inferColName[e]
/   A column name for a SELECT item with no AS (Scala: inferColName): the
/   name for a plain name, "" (none) for anything else.
/     inferColName <a>     is "a"
/     inferColName <u.b>   is "u.b"
/   FIXED: for table.column Scala writes the letter "t", not the table's
/   name, so u.b was named "t.b".
.aqc.gen.inferColName:{[e]
  n:.aqc.nodes.name e;
  if[n = `Id; :.aqc.gen.str e`v];
  if[n = `ColumnAccess; :(.aqc.gen.str e`t),".",.aqc.gen.str e`c];
  ""};

/ addColNames[tuples]
/   Give every item of a SELECT or GROUP BY list a name (Scala:
/   addColNames). tuples is a list of Tuple(expression, alias); the result
/   is a list of (expression; name) pairs. The name is the alias if there
/   is one, else inferColName, else c__0, c__1, ... in order.
/     SELECT a, b + 1, max(c) AS m, d * 2   names   a, c__0, m, c__1
.aqc.gen.addColNames:{[tuples]
  pairs:();
  counter:0;                      / the N of the next c__N
  k:0;
  while[k < count tuples;
    t:tuples k;
    e:t`_1;
    name:$[`None ~ t`_2; .aqc.gen.inferColName e; .aqc.gen.str (t`_2)`value];
    if[0 = count name;
      name:"c__",string counter;
      counter+:1];
    pairs,:enlist (e; name);
    k+:1];
  pairs};

/ noAlias[es]
/   Tuple(e, None) for every expression in es, the shape addColNames
/   reads (Scala: es.map((_, None))).
.aqc.gen.noAlias:{[es]
  out:();
  k:0;
  while[k < count es;
    out:.aqc.ast.append[out; .aqc.ast.tuple (es k; `None)];
    k+:1];
  out};


/ ---------------------------------------------------------------------------
/ Plans (Scala: genRelAlg)
/ ---------------------------------------------------------------------------

/ plan[r]
/   PUBLIC. The q code for plan r and everything under it (Scala:
/   genRelAlg). Afterwards currTable names the table with the result.
.aqc.gen.plan:{[r]
  n:.aqc.nodes.name r;
  if[n = `Table; :.aqc.gen.table r];
  if[n = `Filter; :.aqc.gen.filter[r`t; r`fs]];
  if[n = `SortBy; :.aqc.gen.sortBy[r`t; r`os]];
  if[n = `GroupBy; :.aqc.gen.groupBy r];
  if[n = `Project; :.aqc.gen.project r];
  if[n = `BottomApply; :.aqc.gen.bottomApply r];
  if[n = `TopApply; :.aqc.gen.topApply r];
  if[n = `Join; :.aqc.gen.joinPlan r];
  / ReorderFilter and ColSortBy with several columns only come from the
  / optimizer (version 6)
  '"codegen: not a plan node: ",string n};

/ table[r]
/   FROM t [AS alias] (Scala: genTable): a new temporary table, made from
/   t by base.q's .aq.initTable.
/     FROM t   is   " aq__t0:.aq.initTable[t;\"t\";0b];"
/   The last argument is 1b inside a join: the columns are then renamed
/   alias.column.
.aqc.gen.table:{[r]
  name:.aqc.gen.str r`n;
  alias:$[`None ~ r`alias; name; .aqc.gen.str (r`alias)`value];
  temp:.aqc.gen.newTableName[];
  .aqc.gen.set[`currTable; temp];
  " ",temp,":.aq.initTable[",name,";\"",alias,"\";",(.aqc.gen.bool .aqc.gen.get `renameCols),"];"};

/ bottomApply[r]
/   FROM f(args): the table a function returns (Scala: genBottomApply).
/   The arguments are q variables, not columns (nameAsVar), so that
/   concatenate(t1, t2) works on two tables.
/     FROM f(t1, 2)   is   " aq__t0:.aq.initTable[eval (f;t1;2);\"\";0b];"
.aqc.gen.bottomApply:{[r]
  temp:.aqc.gen.newTableName[];
  .aqc.gen.set[`currTable; temp];
  .aqc.gen.set[`nameAsVar; 1b];
  call:.aqc.gen.funCall .aqc.ast.funCall[r`f; r`args];
  .aqc.gen.set[`nameAsVar; 0b];
  " ",temp,":.aq.initTable[eval ",call,";\"\";0b];"};

/ filter[source; fs]
/   WHERE fs on plan source (Scala: genFilter): one select that keeps the
/   rows where every condition in fs holds.
.aqc.gen.filter:{[source;fs]
  before:.aqc.gen.plan source;
  t:.aqc.gen.get `currTable;
  conds:.aqc.gen.exprList[fs; 1b];
  .aqc.gen.step[before; t; .aqc.gen.select[t; conds; ""; ""]]};

/ groupBy[r]
/   GROUP BY gs [HAVING having] (Scala: genGroupBy). One select with a
/   "by" dictionary; every other column becomes a list of groups:
/     ?[t; (); <group dict>; (<group cols>) _ (.aq.wildCard t)]
/   (_ drops the group columns from the dictionary of all columns, because
/   q adds them as key columns itself). From here on the state is grouped,
/   so later function calls use each. HAVING is a WHERE on the grouped
/   table.
.aqc.gen.groupBy:{[r]
  if[0 < count r`having;
    :.aqc.gen.filter[.aqc.ast.groupBy[r`t; r`gs; ()]; r`having]];
  groups:.aqc.gen.addColNames r`gs;
  before:.aqc.gen.plan r`t;
  t:.aqc.gen.get `currTable;
  byDict:.aqc.gen.exprDict[groups; .aqc.gen.colLookup];
  .aqc.gen.set[`grouped; 1b];
  allCols:.aqc.gen.tableExpr `WildCard;
  groupCols:();
  k:0;
  while[k < count groups;
    groupCols,:enlist .aqc.gen.colLookup groups[k] 1;
    k+:1];
  projection:"(",(.aqc.gen.join[";"; groupCols]),") _ ",allCols;
  .aqc.gen.step[before; t; .aqc.gen.select[t; ""; byDict; projection]]};

/ project[r]
/   SELECT ps (Scala: genProject): a select with a dictionary from column
/   names to expressions.
.aqc.gen.project:{[r]
  columns:.aqc.gen.addColNames r`ps;
  before:.aqc.gen.plan r`t;
  t:.aqc.gen.get `currTable;
  ps:.aqc.gen.exprDict[columns; .aqc.gen.sym];
  .aqc.gen.step[before; t; .aqc.gen.select[t; ""; ""; ps]]};

/ topApply[r]
/   SHOW, DISTINCT or EXEC ARRAYS applied to the result (Scala:
/   genTopApply).
/     SELECT DISTINCT ...   ends with   " aq__t0:.aq.distinct[aq__t0];"
.aqc.gen.topApply:{[r]
  f:.aqc.gen.funName[r`f; 1];
  before:.aqc.gen.plan r`t;
  t:.aqc.gen.get `currTable;
  .aqc.gen.step[before; t; f,"[",t,"]"]};

/ sortBy[source; os]
/   ASSUMING ASC a, DESC b on plan source (Scala: genSortBy, which calls
/   genColSortBy with the columns Set(*)). base.q's .aq.sort sorts every
/   column of the table; after a GROUP BY, .aq.sortGrouped sorts inside
/   each group.
/     " aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `a));((.aq.wildCard aq__t0))];"
.aqc.gen.sortBy:{[source;os]
  before:.aqc.gen.plan source;
  orders:.aqc.gen.orderTuples os;
  allCols:.aqc.gen.exprList[enlist `WildCard; 0b];
  call:$[.aqc.gen.get `grouped; ".aq.sortGrouped"; ".aq.sort"];
  t:.aqc.gen.get `currTable;
  .aqc.gen.step[before; t; call,"[",t,";",orders,";(",allCols,")]"]};

/ orderTuples[os]
/   The sort keys as a list of parse trees (Scala: genOrderTuples): ASC a
/   is (iasc;<a>), DESC a is (idesc;<a>). Written without each even when
/   grouped, because .aq.sortGrouped already works one group at a time;
/   the state is saved first and put back after.
.aqc.gen.orderTuples:{[os]
  calls:();
  k:0;
  while[k < count os;
    o:os k;                                     / Tuple(Asc or Desc, expr)
    f:$[`Asc ~ o`_1; "iasc"; "idesc"];
    calls:.aqc.ast.append[calls; .aqc.ast.funCall[f; .aqc.nodes.one o`_2]];
    k+:1];
  saved:.aqc.gen.st;
  .aqc.gen.set[`grouped; 0b];
  code:.aqc.gen.exprList[calls; 1b];
  .aqc.gen.st:saved;
  code};

/ joinPlan[r]
/   A join of two plans (Scala: genJoin). Both sides are generated first,
/   with renameCols on so their columns are named table.column; then a new
/   temporary table holds the joined result:
/     Cross                 lt cross rt
/     InnerJoinUsing        .aq.joinUsing[.aq.ej;lt;rt;<USING columns>]
/     FullOuterJoinUsing    .aq.joinUsing[.aq.foju;lt;rt;<USING columns>]
/   renameCols stays on for the rest of the query, as in Scala.
.aqc.gen.joinPlan:{[r]
  .aqc.gen.set[`renameCols; 1b];
  left:.aqc.gen.plan r`l;
  lt:.aqc.gen.get `currTable;
  right:.aqc.gen.plan r`r;
  rt:.aqc.gen.get `currTable;
  usingCols:.aqc.gen.exprList[r`cond; 1b];
  jt:.aqc.gen.newTableName[];
  .aqc.gen.set[`currTable; jt];
  kind:r`jt;
  code:$[`Cross ~ kind; lt," cross ",rt;
    `InnerJoinUsing ~ kind; ".aq.joinUsing[.aq.ej;",lt,";",rt,";",usingCols,"]";
    ".aq.joinUsing[.aq.foju;",lt,";",rt,";",usingCols,"]"];
  .aqc.gen.step[left,"\n",right; jt; code]};


/ ---------------------------------------------------------------------------
/ Queries (Scala: genPlan, genLocalQuery, genQuery)
/ ---------------------------------------------------------------------------

/ The q call that resets base.q's per-query state (Scala: initQueryState).
.aqc.gen.initQueryState:" .aq.initQueryState[];";

/ planCode[r; finish; initState]
/   The code for a whole plan (Scala: genPlanInternal): a fresh query
/   state, " .aq.initQueryState[];" if initState, the plan's steps, and a
/   last line made by finish from the name of the result table.
/     finish:{[t] t}   ends the code with the result table, which is then
/                      what the q function returns
.aqc.gen.planCode:{[r;finish;initState]
  .aqc.gen.cleanQueryEnv[];
  code:.aqc.gen.plan r;
  t:.aqc.gen.get `currTable;
  prefix:$[initState; .aqc.gen.initQueryState,"\n"; ""];
  prefix,code,"\n ",finish t};

/ relabel[colNames; t]
/   (colNames, not cols: L does not allow a q built-in as a name)
/   Rename the columns of table t (Scala: genRelabelCols), for WITH
/   name(col1, col2) AS (...). No columns: t unchanged.
/     relabel[("x";"y"); "aq__t0"]   is "`x`y xcol aq__t0"
.aqc.gen.relabel:{[colNames;t]
  if[0 = count colNames; :t];
  syms:"";
  k:0;
  while[k < count colNames; syms,:.aqc.gen.sym colNames k; k+:1];
  syms," xcol ",t};

/ localQuery[l]
/   One WITH query, l = Tuple(name, column names, plan) (Scala:
/   genLocalQuery). Its result is stored in a q variable with its name.
.aqc.gen.localQuery:{[l]
  name:.aqc.gen.str l`_1;
  colNames:l`_2;
  / finish is a projection: the lambda with name and colNames fixed,
  / waiting for the result table t
  finish:{[name;colNames;t] name,":",(.aqc.gen.relabel[colNames; t]),";"}[name; colNames];
  .aqc.gen.planCode[l`_3; finish; 1b]};

/ query[q]
/   PUBLIC. A query with its WITH queries (Scala: genQuery): each WITH
/   query, then the main plan, which ends with the result table.
.aqc.gen.query:{[q] .aqc.gen.queryTo[q; {[t] t}]};

/ queryTo[q; finish]
/   Like query, but the main plan's last line is finish applied to the
/   result table's name (Scala: genQuery and genQueryToVar). A trigger
/   uses it to store the result in a variable:
/     queryTo[q; {[t] "aq__insert_src:",t,";"}]
.aqc.gen.queryTo:{[q;finish]
  parts:();
  k:0;
  while[k < count q`local;
    parts,:enlist .aqc.gen.localQuery (q`local) k;
    k+:1];
  parts,:enlist .aqc.gen.planCode[q`main; finish; 1b];
  .aqc.gen.join["\n"; parts]};
