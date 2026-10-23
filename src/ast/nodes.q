/ nodes.q - walking and rebuilding parse trees (version 3).

/ Ported from the helpers in aquery-master/src/main/scala/edu/nyu/aquery/ast/:
/   expr.scala    Expr.children, Expr.allSubExpressions
/   query.scala   RelAlg.children, RelAlg.expr, RelAlg.transform,
/                 RelAlg.find, RelAlg.takeWhile, Analyzable.attr
/ Later stages (the code generator in v4, the analyses and optimizer in v6)
/ use them. Scala code that nothing calls is left out: Expr.transform,
/ TopLevel.transform, Query.transform and Query.transformQueries.

/ Nodes are the dictionaries described at the top of src/parse/ast.q. Two
/ things from there matter a lot here:
/ - RowId and WildCard are plain symbols (`RowId), not dictionaries, so
/   .aqc.nodes.name is used instead of x`node.
/ - A list of nodes may come back from q as a table (see "A Q TRAP" in
/   ast.q). Lists are only read with count and x k, and only built with
/   .aqc.ast.append and .aqc.ast.concat.

/ A "plan" is a relational algebra node, Scala's RelAlg: Project, Filter,
/ GroupBy, SortBy, Table, TopApply, BottomApply or Join. (Scala's optimizer
/ adds ReorderFilter and ColSortBy; they come with the optimizer in v6.)


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ name[x]
/   The node's Scala class name: x`node, or x itself for a symbol node.
/     name <Id x>     is `Id
/     name `RowId     is `RowId
.aqc.nodes.name:{[x] $[-11h = type x; x; x`node]};

/ one[x]
/   A 1-item list holding x (enlist x would turn a dictionary into a
/   1-row table, see "A Q TRAP" in ast.q).
.aqc.nodes.one:{[x] .aqc.ast.append[(); x]};

/ two[x; y]
/   A 2-item list holding x and y. (x; y) would turn two nodes with the
/   same keys into a 2-row table.
.aqc.nodes.two:{[x;y] .aqc.ast.append[.aqc.nodes.one x; y]};

/ optionItems[o]
/   A Scala Option as a list: () for `None, the value for Some(value).
/   (Scala: o.map(List(_)).getOrElse(Nil))
.aqc.nodes.optionItems:{[o] $[`None ~ o; (); .aqc.nodes.one o`value]};

/ fieldOfEach[xs; field]
/   The field of every node in xs, as a list.
/     fieldOfEach[<Tuple list (a; b)>; `_1]   is the list of first parts
/   (Scala: xs.map(_._1))
.aqc.nodes.fieldOfEach:{[xs;field]
  out:();
  k:0;
  while[k < count xs;
    out:.aqc.ast.append[out; xs[k] field];
    k+:1];
  out};


/ ---------------------------------------------------------------------------
/ Expressions (Scala: trait Expr in expr.scala)
/ ---------------------------------------------------------------------------

/ The expression nodes with no sub-expressions (Scala: children = Nil).
.aqc.nodes.leafExprs:`Id`IntLit`FloatLit`StringLit`DateLit`BooleanLit`TimestampLit,
  `TableColumnValue`RowId`ColumnAccess`WildCard;

/ exprChildren[e]
/   PUBLIC. The direct sub-expressions of expression e, in Scala's order.
/     exprChildren <1 + x>             is (<IntLit 1>; <Id x>)
/     exprChildren <f(a, b)>           is the arguments (<Id a>; <Id b>)
/     exprChildren <CASE c WHEN w1 THEN t1 ELSE z END>
/                                      is (<c>; <IfThen w1 t1>; <z>)
/   Signals an error for anything that is not an expression.
.aqc.nodes.exprChildren:{[e]
  n:.aqc.nodes.name e;
  if[n in .aqc.nodes.leafExprs; :()];
  if[n = `BinExpr; :.aqc.nodes.two[e`l; e`r]];
  if[n = `UnExpr; :.aqc.nodes.one e`v];
  if[n = `FunCall; :e`args];
  if[n = `ArrayIndex; :.aqc.nodes.one e`e];
  if[n = `IfThen; :.aqc.nodes.two[e`c; e`t]];
  / Case: the optional value after CASE, every WHEN, the optional ELSE
  if[n = `Case;
    withWhen:.aqc.ast.concat[.aqc.nodes.optionItems e`cond; e`when];
    :.aqc.ast.concat[withWhen; .aqc.nodes.optionItems e`e]];
  '"exprChildren: not an expression: ",string n};

/ allSubExpressions[e]
/   PUBLIC. Every expression inside e, e included, in Scala's order.
/   Scala's loop, copied exactly because callers may depend on the order:
/     queue := (e), result := (e)
/     until queue is empty:
/       take the first node off queue
/       put its children in front of queue
/       put its children in front of result
/   So deeper nodes come first and e itself is last:
/     allSubExpressions <-x>      is (<Id x>; <UnExpr -x>)
/     allSubExpressions <1 + x>   is (<IntLit 1>; <Id x>; <1 + x>)
.aqc.nodes.allSubExpressions:{[e]
  queue:.aqc.nodes.one e;
  result:.aqc.nodes.one e;
  while[0 < count queue;
    kids:.aqc.nodes.exprChildren queue 0;
    queue:.aqc.ast.concat[kids; 1 _ queue];     / 1 _ drops the first item
    result:.aqc.ast.concat[kids; result]];
  result};


/ ---------------------------------------------------------------------------
/ Plans (Scala: trait RelAlg in query.scala)
/ ---------------------------------------------------------------------------

/ The fields of each plan node that hold its child plans, in Scala's
/ order (Scala: children). Table and BottomApply have none.
.aqc.nodes.planChildFields:`Project`Filter`GroupBy`SortBy`TopApply`Join`Table`BottomApply!
  (enlist `t; enlist `t; enlist `t; enlist `t; enlist `t; `l`r; `symbol$(); `symbol$());

/ childFields[r]
/   The child fields of plan node r. Signals an error if r is not a plan.
.aqc.nodes.childFields:{[r]
  n:.aqc.nodes.name r;
  if[not n in key .aqc.nodes.planChildFields; '"not a plan node: ",string n];
  .aqc.nodes.planChildFields n};

/ planChildren[r]
/   PUBLIC. The child plans of plan node r.
/     planChildren <SELECT a FROM t>          is (<Table t>)
/     planChildren <Join of t and u>           is (<Table t>; <Table u>)
.aqc.nodes.planChildren:{[r]
  fields:.aqc.nodes.childFields r;
  out:();
  k:0;
  while[k < count fields;
    out:.aqc.ast.append[out; r fields k];
    k+:1];
  out};

/ planExprs[r]
/   PUBLIC. The expressions used directly by plan node r, not by its
/   children (Scala: RelAlg.expr).
/     Project      the projected expressions (without their AS names)
/     Filter       the WHERE conditions
/     GroupBy      the grouping expressions, then the HAVING conditions
/     SortBy       the sort expressions (without ASC / DESC)
/     BottomApply  the arguments of FROM f(...)
/     Join         the USING columns
/     Table, TopApply   none
.aqc.nodes.planExprs:{[r]
  n:.aqc.nodes.name r;
  if[n = `Project; :.aqc.nodes.fieldOfEach[r`ps; `_1]];
  if[n = `Filter; :r`fs];
  if[n = `GroupBy; :.aqc.ast.concat[.aqc.nodes.fieldOfEach[r`gs; `_1]; r`having]];
  if[n = `SortBy; :.aqc.nodes.fieldOfEach[r`os; `_2]];
  if[n = `BottomApply; :r`args];
  if[n = `Join; :r`cond];
  if[n in `Table`TopApply; :()];
  '"not a plan node: ",string n};

/ transform[f; r]
/   PUBLIC. Rebuild plan r from the bottom up: first each child plan is
/   transformed, then f is called on the rebuilt node and its result is
/   used. f takes a plan node and returns a plan node; it returns its
/   argument unchanged for nodes it does not handle. (Scala passes a
/   partial function and keeps nodes it is not defined for; same thing.)
/     drop every SortBy:
/       transform[{[x] $[`SortBy = x`node; x`t; x]}; plan]
/   Like Scala, the rebuilt nodes have no position: Scala makes a new node
/   (Project(t.transform(f), ps, attr)) and a new node has no position.
/   Their other fields, attr included, are kept.
.aqc.nodes.transform:{[f;r]
  fields:.aqc.nodes.childFields r;
  rebuilt:r;
  k:0;
  while[k < count fields;
    rebuilt[fields k]:.aqc.nodes.transform[f; r fields k];
    k+:1];
  rebuilt[`pos]:`long$();
  f rebuilt};

/ find[pred; r]
/   PUBLIC. The first node in plan r for which pred returns 1b, as an
/   Option: Some(node), or `None if there is none. Nodes are tried parent
/   first, then children left to right (depth first, pre-order).
/     find[{[x] `Table = x`node}; <SELECT a FROM t, u>]   is Some(<Table t>)
.aqc.nodes.find:{[pred;r]
  queue:.aqc.nodes.one r;
  while[0 < count queue;
    x:queue 0;
    if[pred x; :.aqc.ast.some x];
    queue:.aqc.ast.concat[.aqc.nodes.planChildren x; 1 _ queue]];
  `None};

/ takeWhile[pred; fun; r]
/   PUBLIC. Walk plan r in the same order as find, calling fun on each
/   node, and stop at the first node for which pred returns 0b (that node
/   and everything after it in the walk are left out). Returns the list of
/   fun's results, in walk order.
/     takeWhile[{[x] not `SortBy = x`node}; {[x] x`node}; <a plan>]
/       is the names of the nodes above the first SortBy
/   (Scala builds the list backwards and reverses it at the end; appending
/   gives the same list.)
.aqc.nodes.takeWhile:{[pred;fun;r]
  queue:.aqc.nodes.one r;
  out:();
  while[0 < count queue;
    x:queue 0;
    if[not pred x; :out];
    out:.aqc.ast.append[out; fun x];
    queue:.aqc.ast.concat[.aqc.nodes.planChildren x; 1 _ queue]];
  out};


/ ---------------------------------------------------------------------------
/ Analysis attributes (Scala: trait Analyzable in query.scala)
/ ---------------------------------------------------------------------------

/ Scala gives every plan node (and Query) a map, attr, where analyses store
/ results, e.g. the optimizer's "TABLES_AVAIL". Here a node gets an `attr
/ key, a dictionary, the first time something is stored; the parser never
/ adds it, and the tree printers in ast.q leave it out.

/ attrs[r]
/   PUBLIC. All attributes of r, as a dictionary (empty if none).
.aqc.nodes.attrs:{[r] $[`attr in key r; r`attr; ()!()]};

/ getAttr[r; k; default]
/   PUBLIC. Attribute k of node r, or default if r has none called k.
/     getAttr[r; `TABLES_AVAIL; ()]
/   (Scala: r.attr.getOrElse(k, default))
.aqc.nodes.getAttr:{[r;k;default]
  a:.aqc.nodes.attrs r;
  $[k in key a; a k; default]};

/ setAttr[r; k; v]
/   PUBLIC. A copy of node r with attribute k set to v.
/   (Scala: r.setAttr(k, v))
.aqc.nodes.setAttr:{[r;k;v]
  a:.aqc.nodes.attrs r;
  a[k]:v;
  r[`attr]:a;
  r};

/ clearAttr[r]
/   PUBLIC. A copy of node r with no attributes.
/   (Scala: r.clearAttr)
/   (key r) except `attr is every other key; taking those keys (#) from r
/   gives r without its `attr entry.
.aqc.nodes.clearAttr:{[r] ((key r) except `attr)#r};
