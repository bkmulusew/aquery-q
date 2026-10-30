# src/codegen — q code generation (version 4)

Ports `aquery-master/src/main/scala/edu/nyu/aquery/codegen/KdbGenerator.scala`
(AST to q code) and the `-c` part of the driver `Aquery.scala`, whose role
`aquery.q -compile` takes over. Namespace `.aqc.gen`; `.aqc.compile` is the
entry point at the L prompt.

| q file | what it generates |
|---|---|
| `state.q` | the generator's state (Scala's `CodeState`): one global dictionary `.aqc.gen.st` |
| `expr.q` | expressions: literals, columns, operators, function calls, CASE |
| `plan.q` | query plans: FROM, WHERE, SELECT list, GROUP BY, ASSUMING, joins, WITH |
| `stmt.q` | CREATE, INSERT, UPDATE, DELETE, LOAD, SAVE, FUNCTION |
| `trigger.q` | CREATE TRIGGER, DROP TRIGGER |
| `gen.q` | whole programs: `.aqc.gen.statements`, `.aqc.gen.program`, `.aqc.compile` |

The output matches the jar's byte for byte, except for the five jar bugs
fixed on purpose (marked `FIXED` in the code, listed in
`tests/codegen/divergences.txt`). Expected output for every input is in
`tests/reference_q/`. Running the code is version 5 (`src/runtime/`).
