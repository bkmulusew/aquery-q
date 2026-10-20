# tests/inputs — AQuery source files used by every test level

- `AQuery2/`, `benchmark/`, `financial/`, `function_support/`,
  `resources/`, `triggertests/`: all 81 `.a` files from
  `aquery-master/src/test/`, same sub-folders.
- `scala_snippets/<Suite>/lineNNNN.a`: every AQuery source string in
  `tests/scala/<Suite>.scala`, one file each, named after the Scala line
  (`lineNNNN_K.a` when one line has several). Many are fragments (one
  expression, an ORDER list), not whole programs.
- `edge_cases/`: small hand-written files for lexer corner cases (mixed-case
  keywords, bad dates, unclosed strings/comments, verbatim oddities, ...).
