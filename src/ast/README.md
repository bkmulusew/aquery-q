# src/ast — the AST stage (version 3)

The parse-tree nodes themselves (how they are built and printed) live in
`src/parse/ast.q`, because the parser (v2) builds them. This folder holds
what later stages do with the trees.

| q file | ports | status |
|---|---|---|
| `nodes.q` | the tree helpers in `aquery-master/src/main/scala/edu/nyu/aquery/ast/`: `Expr.children` and `Expr.allSubExpressions` (`expr.scala`); `RelAlg.children`, `RelAlg.expr`, `RelAlg.transform`, `RelAlg.find`, `RelAlg.takeWhile` and the `attr` map of `Analyzable` (`query.scala`) | v3 M1, done |
| `dot.q` | every `dotify` and `Dot.toGraph` (`Dot.scala` and each node class): the `-p` Graphviz output, byte for byte | v3 M2, done |

Namespaces: `.aqc.nodes` (`nodes.q`), `.aqc.dot` (`dot.q`).

`bin/l_m64 aquery.q -p file.a` prints the graph; `dot -Tpdf` (Graphviz)
draws it. Scala's odd corners in the graph are copied on purpose and marked
`SCALA QUIRK` in `dot.q`: labels are not escaped, a CASE or WHEN inside an
expression puts whole node lines into the label, `CREATE ... AS` never
prints the edge to its source, projections are joined with `" ,"`, and a
few labels use node number 0 or 1 instead of their own.

Left out on purpose, because nothing in the Scala compiler calls them:
`Expr.transform` (its `Case` version also has a bug: it puts the ELSE
branch in place of the CASE value), `TopLevel.transform`,
`Query.transform` and `Query.transformQueries`. They can be added when a
later stage needs them.

The optimizer's own plan nodes, `ReorderFilter` and `ColSortBy`, come with
the optimizer (v6).
