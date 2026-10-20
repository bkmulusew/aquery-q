# tests/lexer — version 1 tests

- `test_lexer.q`: hand-written unit tests, grouped by token kind
  (whitespace/comments/EOF, identifiers/keywords, numbers, strings,
  delimiters, dates/timestamps, verbatim, errors/positions).
- `test_golden.q`: for every `golden/<path>.tok`, lexes
  `tests/inputs/<path>.a` with the q lexer and requires identical output.
- `divergences.txt`: inputs `test_golden.q` skips, because the q lexer
  differs from Scala there on purpose (see the main README).
- `golden/`: the Scala lexer's output for every input, made by
  `tools/gen_golden.sh` from `tools/aquery.jar`. **Never edit these by hand**;
  regenerate them if inputs change.

Golden line format (TAB-separated): `kind  text  line:column`, e.g.
`Keyword	SELECT	1:1`. Backslash, TAB, newline, CR in the text are
written as `\\ \t \n \r`. The last line is always `EOF`. A Scala `StringLit` that came from a
timestamp literal is printed as kind `Timestamp` (see tools/TokenDump.java).

Run: `sh tests/run_tests.sh` (or `bin/l_m64 tests/lexer/test_lexer.q`).
