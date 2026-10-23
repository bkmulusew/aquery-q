# src/parse — lexer (version 1) and parser (version 2)

| q file | ports | status |
|---|---|---|
| `util.q` | file reading, `Aquery.scala`'s line normalisation (`getLines().mkString("\n")`, for the future compiler entry point), offset -> line/column | v1, done |
| `keywords.q` | the 102 keywords (with Scala's `fun = true` flag as `isFunction`) and `alwaysUpperCase` from `aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala` | v1, done |
| `jdate.q` | date/timestamp checking from `aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryTokens.scala` (Java `SimpleDateFormat`, non-lenient) | v1, done |
| `lex.q` | `AqueryLexical.token` and `delimiters` (`AqueryParser.scala`), `AqueryTokens.scala`, and the parts of Scala's `StdLexical`/`Scanners` it relies on | v1, done |
| `ast.q` | the AST case classes in `aquery-master/src/main/scala/edu/nyu/aquery/ast/` (building nodes and printing them; the AST features themselves are v3) | v2, done |
| `parser.q` | the grammar rules in `aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala` (715 lines) | v2, done |
| `rewrite.q` | `rewriteLocalStringConstants` in `AqueryParser.scala`: the last step of parsing a program (string constants in WITH queries) | v2, done |

Load order: `util.q`, `keywords.q`, `jdate.q`, `lex.q`, `ast.q`, `parser.q`, `rewrite.q` (`aquery.q` does this).

Namespaces: `.aqc.util`, `.aqc.kw`, `.aqc.jdate`, `.aqc.lex`, `.aqc.ast`, `.aqc.parse`, `.aqc.rewrite` (one per file).
