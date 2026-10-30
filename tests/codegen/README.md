# tests/codegen — version 4 (code generation)

- `test_expr.q`: unit checks for every expression rule, and every
  sub-expression of the 170 compiling programs against `expr_golden/`
  (the jar's `genExpr` output, made by `tools/GenDump.java`).
- `test_codegen.q`: whole programs against `tests/reference_q/` (base.q
  plus the jar's `-a 0 -c` output), and `stmt_cases.a` (one of each
  statement) against `stmt_cases.q`.
- `divergences.txt`: the jar bugs we fixed. Programs touched by bugs 3 and
  4 are skipped; bug 5 (string literals) is in so many files that the
  tests apply the same fix to the expected text instead
  (`tests/lib/jar_fixes.q`).
