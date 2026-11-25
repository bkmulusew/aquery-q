# src/analysis — the type checker (version 6) and the order and join analysis (version 7)

The type checker reads the AST from the parser and lists the mistakes it
can find before any q code runs, for example `WHERE a + 1` (a number where
a boolean is needed), `sums(1, 2, 3)` (wrong number of arguments) or
`SELECT x.c FROM t` (no table called `x`). It is a port of the Scala
`TypeChecker.scala`, and it prints the same messages as `aquery.jar -tc`.

It does not change the AST and does not know column types: a column is
always "unknown", which agrees with every type (the Scala checker does
the same).

Files, in load order:

- `types.q` (`.aqc.tc`): the six type tags (`numeric`, `boolean`,
  `string`, `unit`, `table`, `unknown`) and `consistent`, the rule for
  when one tag may stand where another is expected (`unknown` fits
  everywhere).
- `functions.q` (`.aqc.fn`): the table of built-in functions. Each row has
  the function's signatures (q functions under `.aqc.fn.sig` that take the
  argument tags and return the result tag, or `` `bad ``), its argument
  count, and the order flags the optimizer will need later
  (`orderDependent`, `remOrderDependence`, `usesAggregate`).
  `.aqc.fn.env prog` adds the program's own functions (UDFs), which are
  checked only for their number of arguments.
- `errors.q` (`.aqc.tc.err`): one maker per kind of error (type error,
  bad call, duplicate table, unknown correlation name, ambiguous column,
  illegal expression). An error is a dict `` `kind`args`pos`pos2 ``;
  `.aqc.tc.err.message` turns it into the jar's text, such as
  `Type Error: expected boolean found numeric at [1,23]`.
- `typecheck.q` (`.aqc.tc`): the checker. The first half checks
  expressions (`.aqc.tc.expr` returns the tag and the errors); the second
  half checks queries, UPDATE, DELETE, INSERT, functions and triggers, and
  `.aqc.tc.program` checks a whole program and sorts the errors by
  position.

Ways to call it:

- `.aqc.typecheck "SELECT a FROM t WHERE 1"` returns the messages as a
  list of strings (empty when there are none).
- `l aquery.q -tc file.a` (or `-compile -tc file.a`) prints the messages
  and stops with exit code 1, or compiles the file when there are none.
  Without `-tc` the CLI does not check, like the jar.
- `.aqc.run`, `.aqc.runFile` and `\aq` check by default and refuse to run
  a program with type errors (`'type errors: ...`). Set `.aqc.tc.on:0b`
  to turn this off.

Where q differs from the jar on purpose (each one is in
`tests/analysis/divergences.txt`):

1. A CASE with two or more WHENs crashes the jar (`scala.MatchError`);
   q checks every THEN against the first one.
2. `*` and ROWID have no position in the q tree, so an error about them
   gives the position of the nearest enclosing expression, or `[0,0]`.
3. LOAD, SAVE, CREATE TRIGGER and DROP TRIGGER crash the jar's checker.
   In q the first, second and last have no errors, and a trigger checks
   the statement after DO, with its REFERENCING names usable as tables.

## The order and join analysis (version 7)

Two more files answer the questions the optimizer (version 8) will ask
before it rewrites a query. They are ports of the Scala
`OrderAnalysis.scala` and `JoinAnalysis.scala`, and they also do not
change the AST: they only look at it. Nothing calls them yet except the
tests.

- `order.q` (`.aqc.order`): which functions, expressions and columns
  depend on the order of the rows.
  - `.aqc.order.env prog`: the function table with the program's UDFs
    added one by one, so a UDF is judged with only the UDFs defined
    before it (as Scala does). Each row has `orderDependent`
    (e.g. `sums`), `remOrderDependence` (e.g. `sum` after `sums`) and
    `usesAggregate` (e.g. `max`). An unknown function counts as
    order-dependent and aggregating.
  - `hasOrderDependence`, `usesAggregate`, and the `udf...` versions for
    a whole function.
  - Column sets: a set of columns is a sorted symbol list of keys such as
    `` `$"Id(c1)" `` or `` `$"ColumnAccess(t,c1)" `` (`allCols`,
    `merge`). `colsToSort` gives the columns a query really needs
    sorted: the ones used in an order-dependent expression, plus the ones
    that meet them in the same expression (`interactions`, `indirect`).
  - `hasSortBy`, `getSort` and `isPrefixSort` look at the ASSUMING ORDER
    part of a plan.
- `join.q` (`.aqc.join`): which tables each part of a plan reads, and
  where a WHERE condition can go.
  - `tablesUsed e`: the tables an expression names (`t` in `t.c1`), or
    `` `unknown `` if it uses a plain column like `c1`.
  - `tablesAvailable`, `hasJoin`, and `annotate`, which stores on every
    plan node the tables below it (attribute `TABLES_AVAIL`).
  - `placeFilter[plan; cond]`: the plan with `cond` placed as deep as
    the tables it names allow, e.g. `t1.c1 > 1` goes on `t1` before
    `t1` is joined with `t2`.

Where q differs from the jar on purpose here (part 4 of
`tests/analysis/divergences.txt`): Scala's `placeFilter` drops a
condition that names a table not in the FROM clause (or a table known
only by its alias), and copies a condition with no columns (`1 = 1`)
onto every table. q places both once, on top of the join.

Still to port: the optimizer (version 8, `src/optimization`).
