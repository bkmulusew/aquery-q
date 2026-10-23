#!/bin/sh
# gen_helper_golden.sh: run every case in tests/ast/helper_cases.txt through
# the original Scala AST helpers and write tests/ast/helper_golden.txt, the
# expected results for tests/ast/test_nodes.q.
#
# Usage (from anywhere):   sh tools/gen_helper_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac and java). The jar defaults to tools/aquery.jar.
#
# helper_golden.txt has one block per case, in the same order as the cases:
#   === <kind> TAB <text>
#   --- <helper name>
#   <its result in the golden-file format>
#   --- <next helper name>
#   ...

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
CASES=$ROOT/tests/ast/helper_cases.txt
OUT=$ROOT/tests/ast/helper_golden.txt
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/AstDump.java" "$ROOT/tools/HelperDump.java" || exit 1

: > "$OUT"
# IFS=<tab>: split each line at the first tab into kind and text
grep -v '^#' "$CASES" | grep -v '^$' | while IFS='	' read -r kind text; do
    printf '=== %s\t%s\n' "$kind" "$text" >> "$OUT"
    java -cp "$JAR:$BUILD" HelperDump "$kind" "$text" >> "$OUT"
done
rm -rf "$BUILD"
echo "wrote $OUT"
