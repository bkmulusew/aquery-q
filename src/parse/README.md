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

## Scala quirks the q lexer copies on purpose

1. *(Timestamps: no longer copied, see "Intentional divergences" below.)*
2. **Keywords must be all upper or all lower case.** `SELECT` and `select`
   are keywords; `Select` is an identifier. `INT FLOAT STRING BOOLEAN DATE
   TIMESTAMP` are keywords only in capitals (`int` is an identifier).
3. **Delimiters are `Keyword` tokens** (`(`, `<=`, ...), as in Scala.
4. **Numbers:** `1.` is a number; `.5` is `.` then `5`; `007` keeps its
   zeros; `1.2.3` is `1.2`, `.`, `3`.
5. **Strings** have no escape sequences and cannot contain a newline.
6. **An unclosed `/*` is not a comment**: its `/` and `*` are lexed as
   delimiters and the rest as normal tokens.
7. **Error recovery skips a character.** On an error Scala reports the
   position where its furthest alternative gave up, then restarts one
   character after that. So `!x` gives an error mentioning `x` and `x`
   itself is skipped; `'1/2/2020' AND` loses the `A` (giving `ND`).
8. **Dates are read in a fixed-width window** (10 characters after the
   quote, 19 for timestamps), even when fields are short. Positions after
   a date near the end of input can point past the end, e.g. `2:4` in a
   one-line file.
9. **Dates are parsed like Java's `SimpleDateFormat`** and re-printed:
   `'1/02/20201'` gives `Date 01/02/20201`; spaces before a number are
   skipped (`' 1/02/2020'` is a date); a number may use an exponent
   (`'1/2/1E3'` is year 1000) and is cut to a 32-bit int, so `2E10` wraps
   to a negative (invalid) year. Validation follows Java's default
   calendar: Julian before 15 Oct 1582 (`02/29/1500` is valid), 5–14 Oct
   1582 do not exist, years run from 1 to 292278994.
10. **Invalid dates** give an error after the opening quote; the digits
    and slashes are then lexed as ordinary tokens, and the closing quote
    gives a second error.
11. **Verbatim `<q>...</q>`** reads `<` together with the next character,
    so `<</q>` does not close the block. An unclosed `<q>` is lexed as
    `<`, `q`, `>`, ...
12. **Error messages** are Scala's exact text, e.g.
    ``*** error: `"' expected but \n found``, `*** error: end of input`,
    `*** error: unclosed/invalid date/timestamp`.
13. **Character 26 (0x1A)** is Scala's end-of-file marker. A real 0x1A
    byte in the source becomes an `EOF` token with text `<eof>` and lexing
    carries on after it. It is not whitespace, and it ends a string, a
    `//` comment and a `/* */` comment (which is then unclosed, see 6);
    inside `<q>...</q>` it is an ordinary character.

## Intentional divergences from Scala

1. **Timestamps are their own token kind.** `'01/02/2020D10:11:12'`
   gives `Timestamp 01/02/2020D10:11:12`. Scala gives a `StringLit`, so
   its parser's timestamp rule (`lexical.Timestamp`) can never match.
2. **No fraction of a second (for now).** The closing quote must follow
   the seconds: `'01/02/2020D10:11:12.5'` is an error at the `.`, as if
   Scala's `('.' ~> rep(digit)).?` were not there. Scala accepted
   fractions and copied them into the `StringLit`.

How this is tested: `tools/TokenDump.java` prints a Scala `StringLit`
that starts with `'` as `Timestamp` (only timestamps can). Inputs with a
fraction have no correct Scala output any more; they are listed in
`tests/lexer/divergences.txt`, `test_golden.q` skips them (and prints how
many), and unit tests in `test_lexer.q` cover them instead. No input
outside `tests/inputs/edge_cases/` contains a timestamp.

Not modelled (no test input needs them): Unicode letters/digits in names
(all inputs are ASCII); a timestamp inside a daylight-saving gap of the
machine's time zone, which Java rejects.

Note for version 2: `tools/TokenDump.java`, `.aqc.lex.lexFile` and the
golden tests lex the raw bytes of a file. The real compiler (`Aquery.scala`)
first reads the file with `getLines().mkString("\n")`, which turns `\r\n`
and `\r` into `\n` and drops the final newline (so its EOF position can be
one line earlier). `.aqc.util.normalizeLines` does exactly that; the
compiler's entry point should call it, the lexer itself does not.
