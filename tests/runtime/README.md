# tests/runtime — version 5 (the runtime and the \aq console)

These are the first tests that run the generated q code and check results,
not text.

- `test_run.q`: small AQuery programs run with `.aqc.run` on tables made in
  q, each compared with a table written by hand; also checks that
  `src/runtime/base_l.q` differs from `base.q` only in the two renamed
  lines, and unit checks for the console helpers.
- `test_kdb_suite.q`: the run-and-compare tests of
  `tests/scala/KdbGeneratorTestSuite.scala` (programs in `kdb_suite/`,
  harness in `runner.q`). Each AQuery program must give the same results
  as a q program written by hand. `fintime.a` reads 90 MB of data from
  `$AQUERY_DATA` or `../AQueryKDB/aquery-master/src/test/resources/data`
  and is skipped without it. One known failure is listed in the file.
- `test_console.sh`: types into L. Plain q lines (`console/q_lines.txt`)
  must print exactly what L's own console prints; an AQuery session
  (`console/aq_session.txt`) must print `console/aq_session.expected`;
  and `console/terminal.exp` checks `\aq` in a real terminal with
  `expect`.

`aq_session.expected` was written from a reviewed run. If the console's
output changes on purpose, check the new output by eye before replacing it.
