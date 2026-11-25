# tests/analysis — version 6 (the type checker) and version 7 (order and join analysis)

All goldens come from the jar's own type checker (`tools/TypeDump.java`,
run with the `gen_*_golden.sh` scripts in `tools/`), so the q checker must
print what Scala prints.

- `test_functions.q`: the built-in function table. `sig_golden.txt` has
  the result of every built-in on every combination of argument tags
  (`tools/gen_sig_golden.sh`).
- `test_expr.q`: expressions. `expr_cases.txt` has one case per line
  (`rule<TAB>text`, where the rule is `expr` or `predicate`);
  `expr_golden.txt` has the jar's tag and errors for each
  (`tools/gen_type_golden.sh`).
- `test_program.q`: whole programs. `stmt_cases.a` and
  `stmt_crash_cases.a` are hand-written statements with errors (expected
  output in the matching `.tc` files); `golden/` has the jar's output for
  every program in `tests/inputs` (`tools/gen_program_golden.sh`). Also
  has the cases of `tests/scala/TypeCheckerTestSuite.scala`.
- `test_cli.sh`: `aquery.q -tc` prints the errors and exits 1, and
  compiles a file without errors exactly as `-compile` does.
- `divergences.txt`: the places where q prints something else than the jar
  on purpose, with the reason. A block there replaces the golden block
  with the same `===` line.

A golden line `CRASH ...` means the jar's checker crashed on that
statement; the q checker does not crash, and those statements are
covered by `stmt_crash_cases.a` and the divergences.

## Version 7: order and join analysis

These goldens come from the jar's own `OrderAnalysis` and `JoinAnalysis`
classes, called by `tools/OrderDump.java` (run with
`tools/gen_order_golden.sh`). They cover the cases of
`OrderAnalysisTestSuite.scala` and `JoinAnalysisTestSuite.scala`.

- `test_order_funs.q`: function flags. `order_cases.txt` has expressions
  and UDFs (`context<TAB>rule<TAB>text`; `order_context.a` holds the
  suite's UDFs), with the jar's answers in `order_golden.txt`.
  `order_funs_golden.txt` has the flags of every UDF of every program in
  `tests/inputs` and `order_udfs.a`.
- `test_order.q`: column sets. `order_cols_cases.txt` /
  `order_cols_golden.txt` for single expressions, and
  `order_plans_golden.txt` for every query plan in `tests/inputs` (the
  columns to sort, ASSUMING ORDER, prefix sorts).
- `test_join.q`: join analysis. `join_cases.txt` / `join_golden.txt`
  (tables used, tables available, placing conditions) and
  `join_plans_golden.txt` (every plan with a join in `tests/inputs`,
  with each WHERE above a join placed). Three cases print something else
  on purpose: part 4 of `divergences.txt`.

The goldens are frozen: they were made once with the jar at commit
cb2407c and are checked in. The q tests read only the text files, so
they do not need Java or the jar. `tools/OrderDump.java` and
`tools/gen_order_golden.sh` are kept only to regenerate them.
