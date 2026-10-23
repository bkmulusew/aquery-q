# tests/parser — version 2 (parser)

The q parser turns the lexer's token table into a parse tree. Its tests
check that tree against the original Scala parser in `tools/aquery.jar`.

## Golden files

`golden/<path>.ast` is the expected parser output for `tests/inputs/<path>.a`.
They are made by `sh tools/gen_parser_golden.sh` (needs a JDK 11+, i.e.
`javac`), which runs `tools/AstDump.java` on every input. Never edit them by
hand: change the input or AstDump and regenerate.

Every input gets a golden file. 170 of the 350 inputs parse. The other 180
are expected failures: Scala-test fragments that are not whole programs (a
lone expression, an ORDER list, ...), lexer edge cases, and the 8 AQuery2
files written in a newer dialect.

## Format

A program that does not parse gives one line (fields separated by a TAB):

    FAILURE	1:29	``insert'' expected but 3 found

`1:29` is the line and column of the token where the Scala parser gave up.
The q parser must report the same position; the message is best effort
(Scala's messages are often misleading, as above: the last top-level rule it
tried was INSERT).

A program that parses gives an indented tree, one value per line,
2 spaces per level:

    List
      - Query @1:1
        local: []
        main: Project @1:1
          t: Table @1:15
            n: "t"
            alias: None
          ps: List
            - Tuple
              _1: BinExpr @1:8
                op: Plus
                l: IntLit @1:8
                  v: 1
                r: Id @1:12
                  v: "x"
              _2: None

- `name: ` labels a field of a node, `- ` an item of a list.
- `"t"` is a string, `1` / `0.5` / `true` a number or boolean (doubles are
  printed like Java's `Double.toString`, e.g. `100.0`).
- `Plus`, `Asc`, `TypeInt`, ... are constants with no fields.
- `[]` is an empty list, `None` an empty option.
- `Name @line:col` is a node and where the Scala parser says it starts. Scala
  only records a position for a node built directly by a "positioned" grammar
  rule, so some nodes (`Tuple`, `SortBy`, `Filter`, `GroupBy`, nodes rebuilt
  by the string-constant rewrite, ...) have none.
- `List`, `Some`, `Left`, `Right` and `Tuple` show Scala's containers; their
  parts follow one level deeper (`- ` items, `value: `, or `_1:`, `_2:`, ...).
- `attr` fields (always empty after parsing) are left out.

## Intentional divergences

- A timestamp literal `'01/02/2020D10:11:12'` is printed as `TimestampLit`,
  although Scala builds a `StringLit` (same decision as the lexer's
  `Timestamp` token kind). No input that parses contains one today; the
  unit tests cover it.

`divergences.txt` lists inputs whose golden file the q parser is not
expected to match (none so far).

## Test files

- `test_parser.q`: hand-written unit tests for the expression rules and the
  helpers in `src/parse/ast.q`. Each expected value was printed by the Scala
  parser with `tools/RuleDump.java` and is written in the test as a string.
- `test_rules.q`: single-rule tests for the query and statement rules
  and whole programs. The cases are in `rule_cases.txt` (rule name, TAB,
  text); `sh tools/gen_rule_golden.sh` runs each through the Scala parser and
  writes the expected trees to `rule_golden.txt`. To add a case, add a line
  to `rule_cases.txt` and regenerate; never edit `rule_golden.txt` by hand.
- `test_golden.q`: every input's q parser output must equal its golden
  file (only the position, for a FAILURE). Inputs listed in
  `divergences.txt` are skipped.
