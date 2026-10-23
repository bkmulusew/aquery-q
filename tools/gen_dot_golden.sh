#!/bin/sh
# gen_dot_golden.sh: run the original compiler's -p (Graphviz graph) on
# every input in tests/inputs/ and save its output in tests/ast/golden/,
# the expected results for tests/ast/test_dot.q.
#
# Usage (from anywhere):   sh tools/gen_dot_golden.sh [path/to/aquery.jar]
# Needs Java (java only, no javac). The jar defaults to tools/aquery.jar.
#
# tests/inputs/<path>.a gives tests/ast/golden/<path>.dot. Only inputs that
# the jar can parse get a golden file: for the others the jar prints a
# Scala parse error, which the q compiler does not copy.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
INPUTS=$ROOT/tests/inputs
OUT=$ROOT/tests/ast/golden

rm -rf "$OUT"
made=0
skipped=0
# find ... | sort: every .a file, in a fixed order
for input in $(cd "$INPUTS" && find . -name '*.a' | sort); do
    rel=${input#./}
    target=$OUT/${rel%.a}.dot
    tmp=$(mktemp)
    # 2>/dev/null: Java may print notes such as "Picked up JAVA_TOOL_OPTIONS"
    java -cp "$JAR" edu.nyu.aquery.Aquery -p "$INPUTS/$rel" > "$tmp" 2>/dev/null
    if [ "$(head -n 1 "$tmp")" = "digraph G {" ]; then
        mkdir -p "$(dirname "$target")"
        mv "$tmp" "$target"
        made=$((made + 1))
    else
        rm -f "$tmp"
        skipped=$((skipped + 1))
    fi
done
echo "wrote $made golden files to $OUT ($skipped inputs do not parse)"
