# tests/ast — version 3 (AST stage)

## AST helpers (`test_nodes.q`)

Checks `src/ast/nodes.q` against the Scala helpers in `tools/aquery.jar`.

- `helper_cases.txt`: the inputs, one per line: a grammar rule (`expr`,
  `predicate` or `query`), a TAB, the text.
- `helper_golden.txt`: what the Scala helpers return for each input, made
  by `sh tools/gen_helper_golden.sh` (needs a JDK 11+). It runs
  `tools/HelperDump.java`, which parses the text with the Scala parser and
  calls the helpers on the tree. Never edit it by hand: change the cases
  and regenerate.

Each case in `helper_golden.txt` is a `=== rule<TAB>text` line, then one
section per helper: a `--- <helper>` line and the result in the tree format
of `tests/parser/README.md`. Expressions get `children` and
`allSubExpressions`; plans get `children`, `expr`, three `find`s, a
`takeWhile` and two `transform`s (see the top of `HelperDump.java` for the
exact Scala calls). The q test makes the same sections and compares every
line, positions included.

Scala detail worth knowing: `transform` rebuilds every plan node, and a
new Scala node has no position, so transformed trees print without
`@line:col`. The q `transform` copies this.

The `attr` helpers have no Scala output to compare with, so a few
hand-written checks at the end of `test_nodes.q` cover them.

## The -p graph (`test_dot.q`)

Checks `src/ast/dot.q` against the jar's `-p` output.

- `golden/<path>.dot`: what `java -cp tools/aquery.jar edu.nyu.aquery.Aquery
  -p tests/inputs/<path>.a` prints, made by `sh tools/gen_dot_golden.sh`
  (needs Java, no JDK). Only the 170 inputs the jar can parse get one; for
  the other 180 the jar prints a Scala error message, which q does not copy
  (`aquery.q -p` prints the `-parse` FAILURE line instead).
- `divergences.txt`: inputs the q graph is not expected to match (none).

`test_dot.q` compares every line of every golden file, then checks that
every input whose parser golden (`tests/parser/golden/`) is a tree has a
graph golden, so a golden file cannot go missing unnoticed.
