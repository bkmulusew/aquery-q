/ order.q - the order analysis (version 7).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/analysis/
/ OrderAnalysis.scala. The optimizer (version 8) asks these questions
/ before it moves a sort or a filter:
/   - does this expression depend on the order of the rows? (SUMS does,
/     SUM does not)
/   - does it combine several rows? (an aggregate such as SUM or SUMS)
/   - is a function's result free of row order again? (MAX of a running
/     sum is one number, whatever order the sums came in)
/ This first half (milestone 1) answers them for function names,
/ expressions and UDFs. The second half (milestone 2) works out which
/ columns a query must sort.

/ Every function here takes env, a function table, as its first argument:
/ the same keyed table as the type checker's (src/analysis/functions.q),
/ but built by .aqc.order.env below, which also fills in the three order
/ flags of each UDF.


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ sym[s]
/   A name from the parse tree (a string) as a symbol. A one-character
/   name can be a char atom ("f" alone), which `$ also accepts.
/     sym "myMax"   is `myMax
.aqc.order.sym:{[s] `$s};

/ anyOf[test; xs]
/   Is test x true (1b) for at least one item x of xs? Stops at the
/   first one. test is a function of one argument, often a projection:
/   .aqc.order.hasOrderDependence[env] is hasOrderDependence with its
/   first argument fixed, waiting for the second.
/     anyOf[{x > 2}; 1 5 2]   is 1b
.aqc.order.anyOf:{[test;xs]
  k:0;
  while[k < count xs;
    if[test xs k; :1b];
    k+:1];
  0b};

/ allOf[test; xs]
/   Is test x true for every item x of xs? (1b for an empty xs.)
.aqc.order.allOf:{[test;xs]
  k:0;
  while[k < count xs;
    if[not test xs k; :0b];
    k+:1];
  1b};

/ The literal nodes (Scala: trait Lit).
.aqc.order.litNodes:`IntLit`FloatLit`StringLit`DateLit`BooleanLit`TimestampLit;


/ ---------------------------------------------------------------------------
/ Function flags
/ ---------------------------------------------------------------------------

/ flag[env; f; col; unknown]
/   Flag col (`orderDependent, `remOrderDependence or `usesAggregate) of
/   the function named f (a string), or unknown if env has no such
/   function (a q function like til, or a UDF not defined yet).
.aqc.order.flag:{[env;f;col;unknown]
  name:.aqc.order.sym f;
  $[.aqc.fn.known[env; name]; (env name) col; unknown]};

/ An unknown function gets the safe answers: it may depend on order, it
/ may combine rows, and it does not make its result order-free.
/ (Scala: info(f).map(_.orderDependent).getOrElse(true), and so on.)
/   fnOrderDependent[env; "SUMS"]   is 1b
/   fnOrderDependent[env; "SUM"]    is 0b
/   fnOrderDependent[env; "til"]    is 1b   (unknown)
.aqc.order.fnOrderDependent:{[env;f] .aqc.order.flag[env; f; `orderDependent; 1b]};
.aqc.order.fnUsesAggregate:{[env;f] .aqc.order.flag[env; f; `usesAggregate; 1b]};
.aqc.order.fnRemovesOrderDependence:{[env;f] .aqc.order.flag[env; f; `remOrderDependence; 0b]};


/ ---------------------------------------------------------------------------
/ Expressions
/ ---------------------------------------------------------------------------

/ hasOrderDependence[env; e]
/   Does expression e call an order-dependent function anywhere inside?
/     c1 + max(sums(c2))   is 1b   (SUMS)
/     c1 + max(c4)         is 0b
/   (Scala: hasOrderDependence(e: Expr), through hasOrderDependence0)
.aqc.order.hasOrderDependence:{[env;e]
  if[`FunCall = .aqc.nodes.name e;
    if[.aqc.order.fnOrderDependent[env; e`f]; :1b]];
  / otherwise look inside: the arguments of a call, the parts of
  / anything else (exprChildren gives both)
  .aqc.order.anyOf[.aqc.order.hasOrderDependence[env]; .aqc.nodes.exprChildren e]};

/ usesAggregate[env; e]
/   Does expression e call a function that combines rows anywhere inside?
/     c1 > avg(c1)   is 1b
/     c1 + 2         is 0b
/   (Scala: usesAggregate(e: Expr))
.aqc.order.usesAggregate:{[env;e]
  if[`FunCall = .aqc.nodes.name e;
    if[.aqc.order.fnUsesAggregate[env; e`f]; :1b]];
  .aqc.order.anyOf[.aqc.order.usesAggregate[env]; .aqc.nodes.exprChildren e]};

/ exprRemoves[env; locals; e]
/   Is the value of e free of row order? locals is a dictionary from the
/   names a UDF has seen so far (its parameters and local variables) to
/   that same answer for each.
/   - a name: its answer in locals; a name not there (a column) is not
/   - t.c (a column of a table): no
/   - a call: whether the function removes order (SUM yes, SUMS no; the
/     arguments do not matter, the function decides)
/   - a literal: yes
/   - anything else: yes if every part is (so x + 1 is no when x is no)
/   (Scala: removesOrderDependence(locals, expr))
/   Note that *, ROWID and t("c") have no parts, so they count as yes,
/   as in Scala.
.aqc.order.exprRemoves:{[env;locals;e]
  n:.aqc.nodes.name e;
  if[n = `Id;
    v:.aqc.order.sym e`v;
    :$[v in key locals; locals v; 0b]];
  if[n = `ColumnAccess; :0b];
  if[n = `FunCall; :.aqc.order.fnRemovesOrderDependence[env; e`f]];
  if[n in .aqc.order.litNodes; :1b];
  .aqc.order.allOf[.aqc.order.exprRemoves[env; locals]; .aqc.nodes.exprChildren e]};


/ ---------------------------------------------------------------------------
/ UDFs
/ ---------------------------------------------------------------------------

/ A UDF node has n (its name), args (its parameter names) and cs (its
/ body lines). A body line is Left(Assign(name, e)) for "name := e", or
/ Right(e) for a plain expression; the last line's value is the result.

/ bodyExprs[u]
/   The expression of every body line of UDF u, in order.
/     FUNCTION f(x) { z := sums(x); max(z) }   gives (<sums(x)>; <max(z)>)
.aqc.order.bodyExprs:{[u]
  out:();
  k:0;
  while[k < count u`cs;
    line:(u`cs) k;
    e:$[`Left = line`node; (line`value)`e; line`value];
    out:.aqc.ast.append[out; e];    / append: a list of nodes (see ast.q)
    k+:1];
  out};

/ udfHasOrderDependence[env; u]
/   Does any body line of UDF u depend on row order?
/   (Scala: hasOrderDependence(udf: UDF))
.aqc.order.udfHasOrderDependence:{[env;u]
  .aqc.order.anyOf[.aqc.order.hasOrderDependence[env]; .aqc.order.bodyExprs u]};

/ udfUsesAggregate[env; u]
/   Does any body line of UDF u combine rows?
/   (Scala: usesAggregate(udf: UDF))
.aqc.order.udfUsesAggregate:{[env;u]
  .aqc.order.anyOf[.aqc.order.usesAggregate[env]; .aqc.order.bodyExprs u]};

/ udfRemovesOrderDependence[env; u]
/   Is the result of UDF u free of row order? The body is read line by
/   line, remembering for each local variable whether its value is
/   order-free; the answer is that of the last line.
/     FUNCTION f(x) { z := max(sums(x)); z + 2 }   is 1b
/       (z is order-free, so is 2, so is z + 2)
/     FUNCTION f(x, y) { x + y }                   is 0b
/       (parameters are not order-free)
/   (Scala: removesOrderDependence(udf: UDF))
.aqc.order.udfRemovesOrderDependence:{[env;u]
  / the parameters start as "not order-free"
  locals:(`symbol$())!`boolean$();     / an empty dictionary symbol -> boolean
  k:0;
  while[k < count u`args;
    locals[.aqc.order.sym (u`args) k]:0b;
    k+:1];
  result:1b;                           / Scala's seed; a body is never empty
  k:0;
  while[k < count u`cs;
    line:(u`cs) k;
    $[`Left = line`node;
      / name := e: remember the answer for name
      [assign:line`value;
        result:.aqc.order.exprRemoves[env; locals; assign`e];
        locals[.aqc.order.sym assign`n]:result];
      result:.aqc.order.exprRemoves[env; locals; line`value]];
    k+:1];
  result};


/ ---------------------------------------------------------------------------
/ The function table for one program
/ ---------------------------------------------------------------------------

/ env[prog]
/   The function table for a parsed program: the built-ins, then each UDF
/   in program order, its flags worked out from the functions defined
/   before it. A UDF that calls itself, or a UDF defined further down, is
/   judged as calling an unknown function (order-dependent). A later
/   definition with the same name replaces the earlier one.
/   This differs from the type checker's .aqc.fn.env, where every UDF is
/   known everywhere, because Scala's two analyses differ in this way.
/   prog: list of top-level nodes (what .aqc.gen.parseText returns)
/   (Scala: OrderAnalysis.apply(prog), through FunctionInfo.apply)
.aqc.order.env:{[prog]
  env:.aqc.fn.builtins;
  k:0;
  while[k < count prog;
    if[`UDF ~ .aqc.nodes.name prog k; env:.aqc.order.addUdf[env; prog k]];
    k+:1];
  env};

/ addUdf[env; u]
/   env with a row for UDF u. Its flags are worked out with env as it is,
/   before u is added (Scala: getOrderInfo in OrderAnalysis.apply). The
/   other columns are filled as the type checker's addUdf fills them.
.aqc.order.addUdf:{[env;u]
  r:`name`sigs`orderDependent`remOrderDependence`usesAggregate`nargs!
    (.aqc.order.sym u`n;
      `symbol$();
      .aqc.order.udfHasOrderDependence[env; u];
      .aqc.order.udfRemovesOrderDependence[env; u];
      .aqc.order.udfUsesAggregate[env; u];
      count u`args);
  env upsert r};     / upsert: replaces the row with this name, or adds one


/ ===========================================================================
/ Second half (milestone 2): which columns must be sorted
/ ===========================================================================

/ When a query says ASSUMING ASC c1, the simple plan sorts the whole
/ table. The optimizer (version 8) can sort only the columns whose order
/ matters. These functions find them.

/ HOW A SET OF COLUMNS LOOKS
/ A column is a name (Id c1), a table's column (ColumnAccess t.c1), * or
/ ROWID. Scala keeps columns in a Set, which has no order and ignores
/ source positions. Here a column is kept as its key, a symbol spelled the
/ way Scala prints the column:
/     `$"Id(c1)"   `$"ColumnAccess(t,c1)"   `WildCard   `RowId
/ and a set of columns as a sorted symbol list with no repeats:
/     `$("Id(c1)"; "Id(c2)")
/ so that two sets are the same exactly when ~ says so, and the order is
/ fixed (the golden files print sets this way too). The node for a key
/ can be built back with keyNode, for the code generator in version 8.

/ The column nodes. WildCard and RowId are plain symbols in the tree
/ (Scala objects with no fields).
.aqc.order.colNodes:`Id`ColumnAccess`WildCard`RowId;

/ colKey[c]
/   The key of column node c.
/     colKey <Id c1>             is `$"Id(c1)"
/     colKey <ColumnAccess t.c>  is `$"ColumnAccess(t,c)"
/     colKey `WildCard           is `WildCard
/   Any other expression (only a sort expression can be one) gets
/   "<" and its node name, e.g. `$"<BinExpr>".
.aqc.order.colKey:{[c]
  n:.aqc.nodes.name c;
  str:.aqc.tc.err.str;     / a name as a real string (see errors.q)
  if[n = `Id; :`$"Id(",(str c`v),")"];
  if[n = `ColumnAccess; :`$"ColumnAccess(",(str c`t),",",(str c`c),")"];
  if[n in `WildCard`RowId; :n];
  `$"<",(string n),">"};

/ keyParts[k]
/   The kind, table and column name in key k, as three symbols (an empty
/   symbol ` where there is none).
/     keyParts `$"Id(c1)"                is `Id``c1
/     keyParts `$"ColumnAccess(t,c1)"    is `ColumnAccess`t`c1
/     keyParts `WildCard                 is `WildCard``
.aqc.order.keyParts:{[k]
  s:string k;
  if["Id(" ~ 3#s; :(`Id; `; `$3 _ -1 _ s)];          / drop "Id(" and ")"
  if["ColumnAccess(" ~ 13#s;
    inner:"," vs 13 _ -1 _ s;                        / ("t"; "c1")
    :(`ColumnAccess; `$inner 0; `$inner 1)];
  (k; `; `)};

/ keyNode[k]
/   The column node for key k (with no position).
/     keyNode `$"Id(c1)"   is <Id c1>
.aqc.order.keyNode:{[k]
  p:.aqc.order.keyParts k;
  if[`Id = p 0; :.aqc.ast.id string p 2];
  if[`ColumnAccess = p 0; :.aqc.ast.columnAccess[string p 1; string p 2]];
  k};

/ merge[a; b]
/   The set with the columns of a and of b. (Not called union: that is a
/   q built-in, and L does not accept built-ins as names.)
.aqc.order.merge:{[a;b] asc distinct a,b};

/ unionEach[f; xs]
/   The union of the sets f x, for every item x of xs.
/     unionEach[.aqc.order.allCols; (<c1>; <c2 + c1>)]   is Id(c1) Id(c2)
.aqc.order.unionEach:{[f;xs]
  out:`symbol$();
  k:0;
  while[k < count xs;
    out:.aqc.order.merge[out; f xs k];
    k+:1];
  out};

/ allCols[e]
/   Every column used anywhere in expression e.
/     allCols <c1 + max(t.c2)>   is `$("ColumnAccess(t,c2)"; "Id(c1)")
/   (Scala: allCols(e: Expr))
.aqc.order.allCols:{[e]
  if[(.aqc.nodes.name e) in .aqc.order.colNodes; :enlist .aqc.order.colKey e];
  .aqc.order.unionEach[.aqc.order.allCols; .aqc.nodes.exprChildren e]};

/ allColsOf[es]
/   Every column used in a list of expressions.
/   (Scala: allCols(e: Seq[Expr]))
.aqc.order.allColsOf:{[es] .aqc.order.unionEach[.aqc.order.allCols; es]};


/ ---------------------------------------------------------------------------
/ Columns directly inside an order-dependent call
/ ---------------------------------------------------------------------------

/ directCols[env; collect; e]
/   The columns of e that must be sorted because an order-dependent
/   function reads them. collect says whether the columns met at this
/   level count: Scala's "order-scope". Going down the tree:
/   - a call to an order-dependent function (SUMS): its arguments are
/     collected (collect becomes 1b)
/   - a call to a function that is not order-dependent and removes order
/     (SUM, MAX): its arguments are not (collect becomes 0b)
/   - a column: kept if collect is 1b
/   - anything else (also other calls): look inside, collect unchanged
/     directCols[env; 0b; <c2 + sums(c1 * c2)>]   is Id(c1) Id(c2)
/     directCols[env; 0b; <c1 + c2>]              is empty
/     directCols[env; 1b; <c1 + c2>]              is Id(c1) Id(c2)
/   (Scala: directOrderDependentCols(expr, collect). collect comes before
/   e here so that directCols[env; 1b] can be passed to unionEach.)
.aqc.order.directCols:{[env;collect;e]
  n:.aqc.nodes.name e;
  if[n = `FunCall;
    f:e`f;
    od:.aqc.order.fnOrderDependent[env; f];
    if[(not od) and .aqc.order.fnRemovesOrderDependence[env; f];
      :.aqc.order.unionEach[.aqc.order.directCols[env; 0b]; e`args]];
    if[od; :.aqc.order.unionEach[.aqc.order.directCols[env; 1b]; e`args]]];
  if[(n in .aqc.order.colNodes) and collect; :enlist .aqc.order.colKey e];
  .aqc.order.unionEach[.aqc.order.directCols[env; collect]; .aqc.nodes.exprChildren e]};


/ ---------------------------------------------------------------------------
/ Columns that are combined with each other ("interactions")
/ ---------------------------------------------------------------------------

/ Two columns interact when they are combined row by row, so if one is
/ sorted the other must be too: in c1 + c2 sorting c1 alone would pair
/ the wrong rows. A call that removes order (MAX, SUM) gives one value,
/ so the columns inside it do not interact with those outside:
/     c1 + c2 + max(c3 + sums(c4), c5)   has groups {c1, c2} {c3, c4, c5}

/ sortGroups[gs]
/   The groups gs (a list of sets) with repeats removed, sorted by their
/   text, so that a list of groups also has one fixed form.
.aqc.order.sortGroups:{[gs]
  gs:distinct gs;
  texts:{" " sv string x} each gs;    / Id(c1) Id(c2) -> "Id(c1) Id(c2)"
  gs iasc texts};                     / iasc: the order that sorts texts

/ interactionParts[env; e]
/   Scala's inner function collect: a pair (current; done) where current
/   is the set of columns of e still open (they interact with what e is
/   combined with further up), and done is the list of groups already
/   closed by a call that removes order.
.aqc.order.interactionParts:{[env;e]
  n:.aqc.nodes.name e;
  if[n in .aqc.order.colNodes; :(enlist .aqc.order.colKey e; ())];
  kids:.aqc.nodes.exprChildren e;      / for a call: its arguments
  current:`symbol$();
  done:();
  k:0;
  while[k < count kids;
    part:.aqc.order.interactionParts[env; kids k];
    current:.aqc.order.merge[current; part 0];
    done,:part 1;
    k+:1];
  / a call that removes order closes the group of its arguments, even an
  / empty one (Scala keeps the empty set too: max(1) has one empty group)
  if[n = `FunCall;
    if[.aqc.order.fnRemovesOrderDependence[env; e`f];
      :(`symbol$(); (enlist current),done)]];
  (current; done)};

/ interactions[env; e]
/   The groups of columns that interact in e: the groups closed inside
/   e, plus the columns still open at the top (if there are any).
/     interactions[env; <max(c3, sum(c4 + c5)) * c0 + sums(c6)>]
/       is ({c0, c6}; {c3}; {c4, c5})
/   (Scala: collectInteractions(expr))
.aqc.order.interactions:{[env;e]
  parts:.aqc.order.interactionParts[env; e];
  groups:parts 1;
  if[0 < count parts 0; groups:(enlist parts 0),groups];
  .aqc.order.sortGroups groups};


/ ---------------------------------------------------------------------------
/ Columns that must be sorted because they interact with sorted ones
/ ---------------------------------------------------------------------------

/ sameColumn[a; b]
/   Do keys a and b name the same column, counting c1 and t.c1 as the
/   same (the safe choice: we cannot tell before running which table c1
/   comes from)? t.c1 and u.c1 are different.
/   (Scala: colEquals inside indirectReachable)
.aqc.order.sameColumn:{[a;b]
  if[a = b; :1b];
  pa:.aqc.order.keyParts a;
  pb:.aqc.order.keyParts b;
  kinds:pa[0],pb 0;
  $[kinds ~ `Id`ColumnAccess; pa[2] = pb 2;
    kinds ~ `ColumnAccess`Id; pa[2] = pb 2;
    0b]};

/ inNeed[need; c]
/   Is column c the same as some column in need?
.aqc.order.inNeed:{[need;c] .aqc.order.anyOf[.aqc.order.sameColumn[c]; need]};

/ touches[need; grp]
/   Does grp (a group) hold a column that is the same as some column in need?
/   (The parameter is grp, not group: group is a q built-in, and L
/   does not accept built-ins as names.)
.aqc.order.touches:{[need;grp] .aqc.order.anyOf[.aqc.order.inNeed[need]; grp]};

/ indirect[groups; seed]
/   The columns that must also be sorted because they interact, directly
/   or through other columns, with a column of seed. Repeat until nothing
/   changes: every group that touches the columns found so far adds all
/   its columns. The result leaves out seed itself.
/     indirect[({c4, c5, c7}; {c6, c7}); {c5}]   is {c4, c6, c7}
/   (Scala: indirectReachable(interactions, init))
.aqc.order.indirect:{[groups;seed]
  need:seed;
  left:groups;
  while[1b;
    hit:.aqc.order.touches[need] each left;    / 1b for each group that touches need
    if[not any hit; :need except seed];
    need:.aqc.order.merge[need; raze left where hit];
    left:left where not hit];
  need};

/ colsToSort[env; es; collectAtRoot]
/   Every column that must be sorted so that the expressions es keep
/   their meaning: the columns directly inside an order-dependent call,
/   plus every column that interacts with those. collectAtRoot says
/   whether a column outside any call counts as needing order: yes for a
/   SELECT list (SELECT c1 shows c1 in sorted order), no for a WHERE
/   condition (c1 > 2 keeps the same rows in any order).
/     colsToSort[env; enlist <c1 + sums(c4 * max(c5))>; 1b]   is {c1, c4}
/     colsToSort[env; enlist <c1 + sums(c4 * max(c5))>; 0b]   is {c1, c4}
/       (c1 is not collected at the root, but it interacts with c4)
/   (Scala: colsToSort(exprs, collectAtRoot))
.aqc.order.colsToSort:{[env;es;collectAtRoot]
  direct:.aqc.order.unionEach[.aqc.order.directCols[env; collectAtRoot]; es];
  groups:();
  k:0;
  while[k < count es;
    groups,:.aqc.order.interactions[env; es k];
    k+:1];
  .aqc.order.merge[direct; .aqc.order.indirect[.aqc.order.sortGroups groups; direct]]};


/ ---------------------------------------------------------------------------
/ Sorts in a plan
/ ---------------------------------------------------------------------------

/ An ASSUMING clause becomes a SortBy node; its os field is a list of
/ Tuple(direction, expression) pairs: _1 is `Asc or `Desc, _2 the column.

/ isSortBy[r]
/   Is plan node r a SortBy?
.aqc.order.isSortBy:{[r] `SortBy = .aqc.nodes.name r};

/ hasSortBy[r]
/   Is there a SortBy anywhere in plan r?
/   (Scala: hasSortBy(r))
.aqc.order.hasSortBy:{[r] not `None ~ .aqc.nodes.find[.aqc.order.isSortBy; r]};

/ getSort[r]
/   The sort pairs of the first SortBy in plan r, or an empty list.
/   (Scala: getSort(r))
.aqc.order.getSort:{[r]
  found:.aqc.nodes.find[.aqc.order.isSortBy; r];
  $[`None ~ found; (); (found`value)`os]};

/ isPrefixSort[short; long; sameCol]
/   Is the sort short the start of the sort long: same directions, and
/   columns that sameCol (a function of two expressions) calls the same?
/     ASC c1  is a prefix of  ASC c1, DESC c2
/     ASC c1  is not a prefix of  DESC c1
/   The optimizer decides what counts as the same column (it is stricter
/   when there is a join), so it passes sameCol in.
/   (Scala: isPrefixSort(short, long, colEquals))
.aqc.order.isPrefixSort:{[short;long;sameCol]
  if[(count short) > count long; :0b];
  k:0;
  while[k < count short;
    s:short k;
    l:long k;
    if[not (s`_1) ~ l`_1; :0b];
    if[not sameCol[s`_2; l`_2]; :0b];
    k+:1];
  1b};
