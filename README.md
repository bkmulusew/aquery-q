# aquery-q

> An AQuery compiler written in q. Type SQL-like queries at the q prompt and get tables back.

[AQuery](https://github.com/josepablocam/aquery) is a SQL dialect for ordered data. You say how the rows are sorted (`ASSUMING ASC date`), and then running totals, moving averages and "previous row" questions become one-liners. **aquery-q** compiles AQuery into q code and runs it inside [L](#requirements), an open-source q implementation. Compiling and running happen in the same process, so a query works on the tables you already have.

```
l>t:([] a:1 2 3; b:10 20 30)
l>\aq SELECT a, b FROM t WHERE a > 1
a b
----
2 20
3 30
```

## Features

- **Query from the q prompt.** Start a line with `\aq` and the rest is AQuery. Every other line is plain q.
- **Ordered queries.** `ASSUMING ASC/DESC` sorts the input first, so `sums`, `avgs`, `prev`, `next` and friends follow that order.
- **Most of SQL.** `WHERE`, `GROUP BY ... HAVING`, `CASE`, `WITH` sub-queries and `JOIN ... USING`.
- **Tables you can change.** `CREATE TABLE`, `INSERT`, `UPDATE`, `DELETE`, and CSV files via `LOAD DATA INFILE` and `INTO OUTFILE`.
- **Your own functions.** An AQuery `FUNCTION` becomes an ordinary q function, which you can call from queries and from q.
- **Embedded q.** Anything between `<q>` and `</q>` runs as it is.
- **See every stage.** Turn a `.a` file into a q script, or print its tokens and parse tree along the way.

## Requirements

- A Mac with Apple silicon. The L binary that ships in `bin/l_m64` is built for macOS arm64.
- Nothing else to install. (Java is only needed to rebuild the expected test outputs in `tools/`.)

## Getting started

```sh
git clone git@github.com:bkmulusew/aquery-q.git
cd aquery-q
bin/l_m64 aquery.q
```

This loads the compiler and its runtime, then leaves you at the `l>` prompt. Make a table in q and query it with `\aq`:

```
l>t:([] a:1 2 3; b:10 20 30)
l>\aq SELECT a + b AS s FROM t
s
--
11
22
33
```

> [!TIP]
> Not sure what a query turned into? `-1 .aqc.lastCode;` prints the q code that just ran.

## Usage

### At the prompt

| You type       | What happens                                                |
| -------------- | ----------------------------------------------------------- |
| `\aq <AQuery>` | compiles and runs one line of AQuery, and prints the result |
| any other line | runs as ordinary q, printed the way L prints it             |

`\aq` takes one line, but that line can hold several statements (`INSERT ... INSERT ...`). Only the last statement's result is printed.

### From q code

```q
.aqc.run "SELECT a FROM t WHERE a > 1"    / run AQuery text, returns the result
.aqc.runFile "query.a"                     / run a whole AQuery file
-1 .aqc.lastCode;                          / the q code of the last run
-1 .aqc.compile "SELECT a FROM t";         / the q code, without running it
.aqc.lex.tokens "SELECT a FROM t"          / the tokens, as a table
```

### From the command line

| Command                                         | Prints                                               |
| ----------------------------------------------- | ---------------------------------------------------- |
| `bin/l_m64 aquery.q`                            | nothing: it loads everything and stays at the prompt |
| `bin/l_m64 aquery.q -compile file.a`            | the q code for `file.a`                              |
| `bin/l_m64 aquery.q -compile -out out.q file.a` | writes the q code to `out.q` instead                 |
| `bin/l_m64 aquery.q -parse file.a`              | the parse tree                                       |
| `bin/l_m64 aquery.q -lex file.a`                | the tokens: kind, text, line:column                  |

The generated file starts with the AQuery runtime library (`base.q`) and is meant to be loaded in kdb+. Inside L, use `\aq` or `.aqc.run` instead: they use a copy of the library that L can load.

> [!NOTE]
> The flags are spelled out (`-compile`, `-out`) because L keeps the short ones (`-c`, `-o`, `-s`, `-p`) for its own options.

## Examples

Each block is a real L session. The `l>` lines are what you type.

**Filter, compute and name columns**

```
l>\aq SELECT a, CASE WHEN b > 15 THEN 1 ELSE 0 END AS big FROM t
a big
-----
1 0
2 1
3 1
```

**Group and filter groups.** Strings in double quotes compare with q symbols.

```
l>g:([] k:`x`y`x; v:1 2 3)
l>\aq SELECT v FROM g WHERE k = "x"
v
-
1
3
l>\aq SELECT k, sum(v) AS s FROM g GROUP BY k HAVING sum(v) > 3
k s
---
x 4
```

**Ordered data.** `ASSUMING ASC a` sorts by `a` first, so running totals and "previous/next row" follow that order. `avgs(2, b)` is a moving average over 2 rows.

```
l>u:([] a:3 1 2; b:30 10 20)
l>\aq SELECT a, b, sums(b) AS running, prev(b) AS earlier, next(b) AS later FROM u ASSUMING ASC a
a b  running earlier later
--------------------------
1 10 10              20
2 20 30      10      30
3 30 60      20
l>\aq SELECT a, avgs(2, b) AS avg2 FROM u ASSUMING ASC a
a avg2
------
1 10
2 15
3 25
```

**Joins and sub-queries**

```
l>v:([] a:1 2 4; c:`p`q`r)
l>\aq SELECT a, b, c FROM t INNER JOIN v USING a
a b  c
------
1 10 p
2 20 q
l>\aq WITH big AS (SELECT a, b FROM t WHERE b > 15) SELECT sum(b) AS total FROM big
total
-----
50
```

**Create and change tables**

```
l>\aq CREATE TABLE s (id INT, p INT)
`s
l>\aq INSERT INTO s VALUES(1, 10) INSERT INTO s VALUES(2, 20) INSERT INTO s VALUES(1, 5)
`s
l>\aq UPDATE s SET p = p + 1 WHERE id = 2
l>\aq DELETE FROM s WHERE p < 10
l>s
id p
-----
1  10
2  21
```

**Functions and embedded q**

```
l>\aq FUNCTION dbl(x) { x * 2 }
l>\aq SELECT a, dbl(b) AS twice FROM t
a twice
-------
1 20
2 40
3 60
l>dbl 21
42
l>\aq <q> z:til 3 </q>
l>z
0 1 2
```

**Errors** say where the problem is:

```
l>\aq SELECT FROM t
'aq: parse error at 1:8: identifier expected
```

More AQuery programs, from small snippets to full benchmarks, are in [`tests/inputs/`](tests/inputs).

## Known limitations

> [!WARNING]
>
> - **Triggers don't run yet.** `CREATE TRIGGER` compiles, but the next `INSERT` into its table fails in L with `'type`.
> - **The `-p` graph flag doesn't work in L.** L reads `-p` as its port option. The graph code itself (`src/ast/dot.q`) is tested.
> - **No type checker or query optimizer yet.** Both are planned for the next version.
> - Joins are `JOIN ... USING` only, and keywords must be all upper or all lower case (`SELECT` or `select`, not `Select`). Words like `before` are keywords and can't be column names.
> - Timestamps can't have fractions of a second.

## How it works

A query goes through five stages. Each was built and tested as its own version:

| Stage              | What it does                                              | Code                          |
| ------------------ | --------------------------------------------------------- | ----------------------------- |
| v1 Lexer           | text → tokens (`SELECT`, `a`, `>`, `1`)                   | [`src/parse/`](src/parse)     |
| v2 Parser          | tokens → a parse tree                                     | [`src/parse/`](src/parse)     |
| v3 AST             | helpers to walk and rebuild trees, and the Graphviz graph | [`src/ast/`](src/ast)         |
| v4 Code generation | tree → q code                                             | [`src/codegen/`](src/codegen) |
| v5 Runtime         | runs that code in L, and the `\aq` prompt                 | [`src/runtime/`](src/runtime) |

[`aquery.q`](aquery.q) loads all the stages in order. Each folder has a README that explains its files.

```
aquery-q/
├── aquery.q      entry point: loads every stage, handles the command-line flags
├── bin/l_m64     the L runtime
├── src/          the compiler, one folder per stage
├── tests/        all tests, inputs and expected outputs
└── tools/        scripts that rebuild the expected test outputs
```

## Running the tests

```sh
sh tests/run_tests.sh
```

The script runs all 12 test files in L and ends with `ALL TESTS PASSED` (exit status 0) or lists what failed. There are about 1,700 checks:

| Level           | What is compared                                                                                            | Checks               |
| --------------- | ----------------------------------------------------------------------------------------------------------- | -------------------- |
| Lexer           | tokens of every input file vs the expected tokens                                                           | 107 unit + 346 files |
| Parser          | parse trees vs the expected trees                                                                           | 195 unit + 350 files |
| AST             | tree helpers and graphs vs expected results                                                                 | 45 + 171             |
| Code generation | generated q vs the expected q, byte for byte                                                                | 225 unit + 175 files |
| Runtime         | query results vs tables written by hand; whole programs vs hand-written q; `\aq` typed into a real terminal | 47 + 40 + 3          |

Expected outputs are generated, never edited by hand. To rebuild them, use the scripts in [`tools/`](tools) (they need a JDK).

> [!NOTE]
> One check, `fintime.a` query 0, is a known failure: a string constant in a grouped `WITH` query gives a list per group. `fintime.a` also needs a 90 MB data file, so it is skipped when that file isn't found (set `$AQUERY_DATA` to its folder).

## Troubleshooting

L is close to q but not identical. These are the differences you're most likely to hit when you write q next to AQuery:

- **Built-in names can't be variables or parameters** in L: `cols`, `count`, `next`, `type`, `key`, `value`, `differ`, `all` and others. When in doubt, pick a longer name.
- **A line with only `/` starts a block comment** that runs until a line with only `\`, and everything in between is silently skipped.
- **`"x"` is one character, not a string.** Use `(),"x"` or `enlist "x"` when you need a one-character string.
- **Unknown backslash commands go to the shell.** If `\aq` gives `sh: aq: command not found`, the compiler isn't loaded: start L with `bin/l_m64 aquery.q`.

## Credits

This project builds on:

- [josepablocam/aquery](https://github.com/josepablocam/aquery): the AQuery language and its q runtime library (`src/runtime/base.q`).
- [pequeniajugar/AQueryKDB](https://github.com/pequeniajugar/AQueryKDB): AQuery on kdb+, including the test programs and benchmarks in `tests/inputs/`.
- L, an open-source implementation of q, which runs everything here.
