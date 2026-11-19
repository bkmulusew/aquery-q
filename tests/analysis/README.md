# tests/analysis — version 6 (the type checker)

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

`OrderAnalysisTestSuite.scala` and `JoinAnalysisTestSuite.scala` will be
ported in version 7.
