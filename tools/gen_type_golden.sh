#!/bin/sh
# gen_type_golden.sh: run every expression in tests/analysis/expr_cases.txt
# through the original Scala type checker and write
# tests/analysis/expr_golden.txt, the expected results for
# tests/analysis/test_expr.q. See tools/TypeDump.java (mode expr).
#
# Usage (from anywhere):   sh tools/gen_type_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac and java). The jar defaults to tools/aquery.jar.
#
# Each case is "<rule><TAB><text>", the rule being expr or predicate.
# expr_golden.txt has one block per case, in the same order as the cases:
#   === <rule><TAB><the expression>
#   TYPE<TAB>numeric
#   ERROR<TAB>...

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
CASES=$ROOT/tests/analysis/expr_cases.txt
OUT=$ROOT/tests/analysis/expr_golden.txt
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/TypeDump.java" || exit 1

: > "$OUT"
# IFS=<tab>: split each line at the first tab into rule and text
grep -v '^#' "$CASES" | grep -v '^$' | while IFS='	' read -r rule text; do
    printf '=== %s\t%s\n' "$rule" "$text" >> "$OUT"
    java -cp "$JAR:$BUILD" TypeDump "$rule" "$text" >> "$OUT"
done
rm -rf "$BUILD"
echo "wrote $OUT"
