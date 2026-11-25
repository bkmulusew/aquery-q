/ join.q - the join analysis (version 7).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/analysis/
/ JoinAnalysis.scala. The optimizer (version 8) uses it to push WHERE
/ conditions below joins: a condition that only needs table t1 can be
/ applied to t1 before t1 is joined with anything, so the join has fewer
/ rows to combine.
/     SELECT ... FROM t1, t2 WHERE t1.c1 > 1 AND t1.c1 = t2.c1
/ becomes, as a plan:
/     Filter t1.c1 = t2.c1          (needs both tables: stays on top)
/       Join Cross
/         Filter t1.c1 > 1          (needs only t1: placed on t1)
/           Table t1
/         Table t2

/ Table names are symbols. A set of table names is a sorted symbol list
/ with no repeats, like the column sets of order.q:  `t1`t2
/ A table with an alias (t1 AS a) is known by its alias only.


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ merge[a; b]
/   The set with the table names of a and of b.
.aqc.join.merge:{[a;b] asc distinct a,b};

/ subset[a; b]
/   Is every name of a also in b? (Always 1b for an empty a.)
.aqc.join.subset:{[a;b] all a in b};

/ The plan attribute that holds the table names available at a node
/ (Scala: AVAIL_KEY, "TABLES_AVAIL").
.aqc.join.availKey:`TABLES_AVAIL;

/ getAvail[r]
/   The table names stored on plan node r, or an empty set.
/   (Scala: getAvailTableNames)
.aqc.join.getAvail:{[r] .aqc.nodes.getAttr[r; .aqc.join.availKey; `symbol$()]};

/ setAvail[r; names]
/   r with its available table names set to names.
/   (Scala: setAvailTableNames)
.aqc.join.setAvail:{[r;names] .aqc.nodes.setAttr[r; .aqc.join.availKey; names]};


/ ---------------------------------------------------------------------------
/ Expressions
/ ---------------------------------------------------------------------------

/ The answer of tablesUsed when a plain column name (c1, *, ROWID) appears:
/ c1 could come from any table, so the tables needed are not known before
/ the query runs. It is a symbol atom; a known answer is a symbol list
/ (possibly empty), so the two can be told apart with type.
.aqc.join.unknown:`unknown;

/ isUnknown[used]
/   Is used (an answer of tablesUsed) the unknown answer?
/   (-11h is the type of a symbol atom; a symbol list is 11h.)
.aqc.join.isUnknown:{[used] -11h = type used};

/ tablesUsed[e]
/   The table names that expression e names (t in t.c1), or unknown if e
/   uses a plain column anywhere.
/     tablesUsed <t.c1 * h(ot.c3)>   is `ot`t
/     tablesUsed <f(c1) * t.c1>      is unknown (because of c1)
/     tablesUsed <1 + 2>             is an empty list
/   (Scala: tableNamesUsed, which returns None for unknown)
.aqc.join.tablesUsed:{[e]
  n:.aqc.nodes.name e;
  if[n = `ColumnAccess; :enlist `$.aqc.tc.err.str e`t];
  if[n in `Id`WildCard`RowId; :.aqc.join.unknown];
  kids:.aqc.nodes.exprChildren e;
  used:`symbol$();
  k:0;
  while[k < count kids;
    u:.aqc.join.tablesUsed kids k;
    if[.aqc.join.isUnknown u; :.aqc.join.unknown];
    used:.aqc.join.merge[used; u];
    k+:1];
  used};

/ isEqualitySelection[e]
/   Is the top of e an equality test (= or !=), possibly under NOT?
/     c1 = 2                 is 1b
/     not(not(c1 = c2 * 3))  is 1b
/     f(c4 = 5)              is 0b  (the top is the call f)
/   Nothing in the compiler calls this yet (Scala does not either); it is
/   ported so that JoinAnalysisTestSuite.scala ports completely.
/   (Scala: isEqualitySelection)
.aqc.join.isEqualitySelection:{[e]
  n:.aqc.nodes.name e;
  if[n = `FunCall;
    args:e`args;
    / NOT written as a call, in any case: not(x)
    if[("NOT" ~ upper .aqc.tc.err.str e`f) and 1 = count args;
      :.aqc.join.isEqualitySelection args 0];
    :0b];
  if[n = `UnExpr;
    if[`Not = e`op; :.aqc.join.isEqualitySelection e`v];
    :0b];
  if[n = `BinExpr; :(e`op) in `Eq`Neq];
  0b};


/ ---------------------------------------------------------------------------
/ Plans
/ ---------------------------------------------------------------------------

/ tableName[t]
/   The name a Table node is known by: its alias if it has one.
/     tableName <Table t1 AS t_one>   is `t_one
/   (Scala: tableName)
.aqc.join.tableName:{[t]
  alias:t`alias;
  `$.aqc.tc.err.str $[`None ~ alias; t`n; alias`value]};

/ tablesAvailable[r]
/   The names of all tables that feed plan r.
/     tablesAvailable <FROM t1 as t_one, t2 INNER JOIN t3 USING cx>
/       is `t2`t3`t_one
/   (Scala: tablesAvailable, mapped through tableName; Scala returns the
/   Table nodes, but every caller only wants their names)
.aqc.join.tablesAvailable:{[r]
  if[`Table = .aqc.nodes.name r; :enlist .aqc.join.tableName r];
  kids:.aqc.nodes.planChildren r;
  names:`symbol$();
  k:0;
  while[k < count kids;
    names:.aqc.join.merge[names; .aqc.join.tablesAvailable kids k];
    k+:1];
  names};

/ hasJoin[r]
/   Is there a join (also a comma, FROM t1, t2) anywhere in plan r?
/   (Scala: hasJoin)
.aqc.join.hasJoin:{[r]
  if[`Join = .aqc.nodes.name r; :1b];
  .aqc.order.anyOf[.aqc.join.hasJoin; .aqc.nodes.planChildren r]};

/ annotateNode[r]
/   r with its available table names stored, assuming its children have
/   theirs already: a node with no children (a table) computes them, any
/   other node takes the names of its children together.
.aqc.join.annotateNode:{[r]
  kids:.aqc.nodes.planChildren r;
  if[0 = count kids; :.aqc.join.setAvail[r; .aqc.join.tablesAvailable r]];
  names:`symbol$();
  k:0;
  while[k < count kids;
    names:.aqc.join.merge[names; .aqc.join.getAvail kids k];
    k+:1];
  .aqc.join.setAvail[r; names]};

/ annotate[r]
/   Plan r with every node's available table names stored (bottom up, so
/   each node sees its children's names).
/   (Scala: annotateWithAvailTableNames)
.aqc.join.annotate:{[r] .aqc.nodes.transform[.aqc.join.annotateNode; r]};


/ ---------------------------------------------------------------------------
/ Placing a WHERE condition
/ ---------------------------------------------------------------------------

/ placeAt[needs; cond; r]
/   One step of placeFilter, called on every node of the plan from the
/   bottom up: wrap r in Filter(r, cond) if r is the deepest node that has
/   every table in needs, otherwise return r as it is.
/   - a table that has all of needs
/   - a join that has all of needs, while neither of its sides does
/   The new Filter gets r's available table names.
.aqc.join.placeAt:{[needs;cond;r]
  n:.aqc.nodes.name r;
  avail:.aqc.join.getAvail r;
  here:0b;
  if[n = `Table; here:.aqc.join.subset[needs; avail]];
  if[n = `Join;
    here:.aqc.join.subset[needs; avail]
      and (not .aqc.join.subset[needs; .aqc.join.getAvail r`l])
      and not .aqc.join.subset[needs; .aqc.join.getAvail r`r]];
  if[not here; :r];
  f:.aqc.ast.filter[r; .aqc.nodes.one cond];
  .aqc.join.setAvail[f; avail]};

/ placeFilter[r; cond]
/   Plan r with the WHERE condition cond placed as deep as the tables it
/   names allow. A condition with a plain column (unknown tables) needs
/   every table, so it goes on top of the last join. r must have a join.
/     placeFilter[<FROM t1, t2>; <t1.c1 > 1>]
/       is  Join Cross (Filter t1.c1 > 1 (Table t1)) (Table t2)
/   To place several conditions keeping their order, place the last one
/   first: each one ends up above the ones placed before it.
/   Two cases where q differs from Scala on purpose, because Scala gets
/   them wrong (tests/analysis/divergences.txt, part 4):
/   - a condition naming a table that is not in the plan (zz.c1 > 1):
/     Scala places it nowhere, so it silently disappears and the query
/     returns rows it should reject. q treats it like a plain column and
/     places it on top, so the condition is kept, as it is without the
/     optimizer.
/   - a condition with no columns at all (1 = 1): Scala places a copy on
/     every table. q places it once, on top.
/   (Scala: placeFilter)
.aqc.join.placeFilter:{[r;cond]
  if[not .aqc.join.hasJoin r; '"Requires rel alg op with join"];
  annotated:$[0 = count .aqc.join.getAvail r; .aqc.join.annotate r; r];
  everyTable:.aqc.join.getAvail annotated;     / every table in the plan
  needs:.aqc.join.tablesUsed cond;
  if[.aqc.join.isUnknown needs; needs:everyTable];
  / the two fixes: no tables, or a table the plan does not have
  if[(0 = count needs) or not .aqc.join.subset[needs; everyTable]; needs:everyTable];
  .aqc.nodes.transform[.aqc.join.placeAt[needs; cond]; annotated]};
