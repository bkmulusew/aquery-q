# tests/runtime/kdb_suite — programs for test_kdb_suite.q

The run-and-compare cases of `tests/scala/KdbGeneratorTestSuite.scala`.
Each case is an AQuery program (`.a`) and a q program written by hand
(`.q`) that must give the same results; `tests/runtime/runner.q` runs them.

- `simple_expressions`, `create`, `insert`, `load_save`, `update_delete`,
  `simple_queries`: the AQuery and q strings written inside the Scala tests,
  copied into files. One change: `update_delete.q` drops the `0N!` that
  printed both 1000-row results (printing does not change the result).
- `simple.q`, `monetdb.q`, `pandas.q`, `fintime.q`, `load_fintime.q`:
  copied unchanged from `aquery-master/src/test/resources/q/`. Their AQuery
  programs are already in `tests/inputs/resources/`.
- `runner_scala.q`: the original q runner, kept for reference.
