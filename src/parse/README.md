# src/parse — lexer (version 1) and parser (version 2)

| q file | ports | status |
|---|---|---|
| `util.q` | file reading, `Aquery.scala`'s line normalisation (`getLines().mkString("\n")`, for the future compiler entry point), offset -> line/column | v1, done |
| `keywords.q` | the 102 keywords (with Scala's `fun = true` flag as `isFunction`) and `alwaysUpperCase` from `aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala` | v1, done |
| `jdate.q` | date/timestamp checking from `aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryTokens.scala` (Java `SimpleDateFormat`, non-lenient) | v1, done |
| `lex.q` | `AqueryLexical.token` and `delimiters` (`AqueryParser.scala`), `AqueryTokens.scala`, and the parts of Scala's `StdLexical`/`Scanners` it relies on | v1, done |
| *(parser)* | `aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala` (715 lines, grammar rules) | planned for v2 |

Load order: `util.q`, `keywords.q`, `jdate.q`, `lex.q` (`aquery.q` does this).

Namespaces: `.aqc.util`, `.aqc.kw`, `.aqc.jdate`, `.aqc.lex` (one per file).
