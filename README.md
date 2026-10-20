# aquery-q: the AQuery compiler, rewritten in q for L

A port of the Scala AQuery compiler (`AQueryKDB/aquery-master`) to q,
running on L (an open-source q implementation). The folder is
self-contained: the L runtime, the original compiler (as a jar, used only
to make test data), all test inputs and the original Scala tests are inside.

**Version 1 = the lexer only.** It reproduces the Scala lexer's output
token for token, including its odd corners (see "Scala quirks" below).
The parser, AST, analysis, optimiser and code generator come in later
versions.

## Quick start

```sh
sh tests/run_tests.sh                              # all tests (needs only bin/l_m64)
bin/l_m64 aquery.q -lex tests/inputs/financial/Q1.a   # print tokens of a file
bin/l_m64 aquery.q                                 # load the compiler, stay in L
```

In L, after loading `aquery.q`:

```q
.aqc.lex.tokens "SELECT a FROM t"           / table: kind, text, line, col
.aqc.lex.formatTokens .aqc.lex.tokens "x"    / lines in the golden-file format
.aqc.lex.lexFile "tests/inputs/financial/Q1.a"
```

## Folder layout

```
aquery-q/
├── README.md
├── aquery.q               entry point: loads every stage; "-lex file.a" prints tokens
├── bin/l_m64              L runtime (copy of AQueryKDB/l-runtime/l_m64)
├── src/
│   ├── parse/             v1: util.q, keywords.q, jdate.q, lex.q  (parser in v2)
│   ├── ast/               planned: README names the Scala files to port
│   ├── analysis/          planned
│   ├── optimization/      planned
│   ├── codegen/           planned
│   └── runtime/base.q     q support library, copied UNCHANGED from aquery-master
├── tests/
│   ├── run_tests.sh       runs every test file in L; exit 1 on any failure
│   ├── lib/testing.q      tiny test library (.test.check, .test.finish)
│   ├── lexer/             v1: test_lexer.q (unit), test_golden.q, golden/*.tok
│   ├── parser/ ast/ analysis/ optimization/ codegen/   planned (READMEs)
│   ├── inputs/            every .a from aquery-master/src/test, Scala test
│   │                      snippets (scala_snippets/), edge cases (edge_cases/)
│   ├── reference_q/       the jar's compiled q output for every input
│   └── scala/             the 6 original Scala test suites, as-is
└── tools/
    ├── aquery.jar         the original compiler (reference only)
    ├── TokenDump.java     prints the Scala lexer's tokens for one file
    ├── gen_golden.sh      regenerates tests/lexer/golden/ (needs a JDK)
    └── gen_reference_q.sh regenerates tests/reference_q/  (needs a JDK)
```

Only `bin/`, `aquery.q`, `src/` and `tests/` are needed to run the compiler
and its tests. `tools/` needs Java and is only for regenerating test data.

## How the lexer is tested

1. **Unit tests** (`tests/lexer/test_lexer.q`): short strings, one group
   per token kind.
2. **Golden files** (`tests/lexer/test_golden.q`): `tools/TokenDump.java`
   runs the real Scala lexer from `aquery.jar` on every file in
   `tests/inputs/` and saves the tokens in `tests/lexer/golden/`. The q
   lexer must produce exactly the same lines. Golden files are never edited
   by hand; if the Scala output looks wrong, the q lexer still matches it
   and the oddity is listed below.

The Scala test suites have no lexer-level tests (they test lexer and parser
together), which is why version 1 relies on golden files.

## Scala quirks the q lexer copies on purpose

1. **Timestamps are strings.** `'01/02/2020D10:11:12.5'` becomes a
   `StringLit`, not a timestamp token. The fraction is copied as written,
   even a bare `.`.
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

Not modelled (no test input needs them): Unicode letters/digits in names
(all inputs are ASCII); a timestamp inside a daylight-saving gap of the
machine's time zone, which Java rejects.

Note for version 2: `tools/TokenDump.java`, `.aqc.lex.lexFile` and the
golden tests lex the raw bytes of a file. The real compiler (`Aquery.scala`)
first reads the file with `getLines().mkString("\n")`, which turns `\r\n`
and `\r` into `\n` and drops the final newline (so its EOF position can be
one line earlier). `.aqc.util.normalizeLines` does exactly that; the
compiler's entry point should call it, the lexer itself does not.

## q / L notes for readers new to q

- q evaluates **right to left** and `and`/`or` evaluate both sides.
- A line containing only `/` (even with trailing spaces) **starts a
  multi-line comment** that runs until a line containing only `\`. The
  source files therefore never use a bare `/` line.
- L rejects q built-in names as parameters or locals (`cols`, `count`,
  `next`, `type`, `key`, `value`, ...). That is why `src/runtime/base.q`
  does not fully load in L (see `src/runtime/README.md`).
- `"x"` (one character) is a char atom, not a string; `(),x` makes it a
  1-character string. `_` cannot be used in names (it is the drop operator).
- L differences found so far: `"," sv strings` and `-3!` on atoms fail
  in L, so the code avoids them.
- In a script, a top-level expression that is not an assignment prints its
  result in L, so such lines end with `;`.

## Regenerating test data

```sh
sh tools/gen_golden.sh         # ~1 minute; rewrites tests/lexer/golden/
sh tools/gen_reference_q.sh    # several minutes; rewrites tests/reference_q/
```
