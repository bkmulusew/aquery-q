# tests/optimization — planned (version 8)

Will port `tests/scala/BasicOptimizerTestSuite.scala`. Inputs are in
`tests/inputs/scala_snippets/BasicOptimizerTestSuite/`.

End-to-end goldens are already frozen: `tests/reference_q/*.opt.q` is
the q code the jar prints with its optimizer on (`-a 1`) for every
program in `tests/inputs` (made by `tools/gen_reference_q.sh`). 49 of the
170 differ from the plain `.q` files, so those are the programs the
optimizer changes. Version 8 must print the same code (or a listed
divergence).
