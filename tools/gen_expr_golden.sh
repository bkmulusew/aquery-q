#!/bin/sh
# gen_expr_golden.sh: run the original code generator on every expression
# of every input in tests/inputs/ (tools/GenDump.java) and save the result
# in tests/codegen/expr_golden/, the expected results for
# tests/codegen/test_expr.q.
#
# Usage (from anywhere):   sh tools/gen_expr_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac). The jar defaults to tools/aquery.jar.
#
# tests/inputs/<path>.a gives tests/codegen/expr_golden/<path>.txt. Only
# inputs that the jar can parse get a golden file.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
INPUTS=$ROOT/tests/inputs
OUT=$ROOT/tests/codegen/expr_golden
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/GenDump.java" || exit 1

rm -rf "$OUT"
made=0
skipped=0
# find ... | sort: every .a file, in a fixed order
for input in $(cd "$INPUTS" && find . -name '*.a' | sort); do
    rel=${input#./}
    target=$OUT/${rel%.a}.txt
    tmp=$(mktemp)
    # 2>/dev/null: Java may print notes such as "Picked up JAVA_TOOL_OPTIONS"
    java -cp "$JAR:$BUILD" GenDump "$INPUTS/$rel" > "$tmp" 2>/dev/null
    if [ "$(head -n 1 "$tmp")" = "FAILURE" ]; then
        rm -f "$tmp"
        skipped=$((skipped + 1))
    else
        mkdir -p "$(dirname "$target")"
        mv "$tmp" "$target"
        made=$((made + 1))
    fi
done
rm -rf "$BUILD"
echo "wrote $made golden files to $OUT ($skipped inputs do not parse)"
