# tests/parser — planned for version 2

Will port `tests/scala/ParserTestSuite.scala` (13 tests: arithmetic, case
expressions, create/insert, trigger, io, update, delete, udf, from-clause,
complete query, and whole-program parses of `tests/inputs/resources/`
`simple.a`, `fintime.a`, `monetdb.a`, `pandas.a`). Its source strings are
already extracted into `tests/inputs/scala_snippets/ParserTestSuite/`.
