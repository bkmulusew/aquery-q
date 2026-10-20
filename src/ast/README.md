# src/ast — AST node definitions (planned, version 2)

Empty in version 1. Will port the Scala AST, which the parser (v2) builds:

- `aquery-master/src/main/scala/edu/nyu/aquery/ast/AST.scala` (43 lines): base traits, positions
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/TopLevel.scala` (26): top-level program items
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/expr.scala` (322): expressions
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/query.scala` (418): queries and relational algebra nodes
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/data.scala` (110): CREATE / INSERT / UPDATE / DELETE / LOAD / SAVE
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/udf.scala` (38): user-defined functions
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/trigger.scala` (41): triggers
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/types.scala` (31): column types
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/VerbatimCode.scala` (15): `<q> ... </q>` blocks
- `aquery-master/src/main/scala/edu/nyu/aquery/ast/Dot.scala` (66): the `-p` dot-graph printer
