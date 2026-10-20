# src/codegen — q code generation (planned, last stage)

Empty in version 1. Will port:

- `aquery-master/src/main/scala/edu/nyu/aquery/codegen/KdbGenerator.scala` (1460 lines): AST -> q code
- `aquery-master/src/main/scala/edu/nyu/aquery/codegen/BackEnd.scala` (11), `aquery-master/src/main/scala/edu/nyu/aquery/codegen/SimpleState.scala` (25)
- the command-line driver `aquery-master/src/main/scala/edu/nyu/aquery/Aquery.scala` (130), whose role `aquery.q` takes over

Expected output for every input is in `tests/reference_q/`.
