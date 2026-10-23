#!/bin/sh
# gen_rule_golden.sh: run every case in tests/parser/rule_cases.txt through
# the original Scala parser and write tests/parser/rule_golden.txt, the
# expected results for tests/parser/test_rules.q.
#
# Usage (from anywhere):   sh tools/gen_rule_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac and java). The jar defaults to tools/aquery.jar.
#
# rule_golden.txt has one block per case, in the same order as the cases:
#   === <rule> TAB <text>
#   <the tree in the golden-file format, or FAILURE TAB line:col TAB message>

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
CASES=$ROOT/tests/parser/rule_cases.txt
OUT=$ROOT/tests/parser/rule_golden.txt
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/AstDump.java" "$ROOT/tools/RuleDump.java" || exit 1

: > "$OUT"
# IFS=<tab>: split each line at the first tab into rule and text
grep -v '^#' "$CASES" | grep -v '^$' | while IFS='	' read -r rule text; do
    printf '=== %s\t%s\n' "$rule" "$text" >> "$OUT"
    java -cp "$JAR:$BUILD" RuleDump -tree "$rule" "$text" >> "$OUT"
done
rm -rf "$BUILD"
echo "wrote $OUT"
