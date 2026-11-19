#!/bin/sh
# gen_program_golden.sh: type check every tests/inputs/<path>.a with the
# original Scala type checker and write tests/analysis/golden/<path>.tc,
# the expected results for tests/analysis/test_program.q. Inputs that do
# not parse get no golden file. Also writes tests/analysis/stmt_cases.tc
# and stmt_crash_cases.tc. See tools/TypeDump.java (mode program).
#
# Usage (from anywhere):   sh tools/gen_program_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac and java). The jar defaults to tools/aquery.jar.
# Takes a few minutes: the JVM starts once per input.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
OUT=$ROOT/tests/analysis/golden
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/TypeDump.java" || exit 1

# check <input .a> <output .tc>: run TypeDump; no output file if no parse
check() {
    result=$(java -cp "$JAR:$BUILD" TypeDump program "$1")
    [ "$result" = "PARSE-FAILURE" ] && return
    mkdir -p "$(dirname "$2")"
    if [ -n "$result" ]; then printf '%s\n' "$result" > "$2"; else : > "$2"; fi
}

rm -rf "$OUT"
cd "$ROOT/tests/inputs" || exit 1
find . -name '*.a' | sort | while IFS= read -r f; do
    rel=${f#./}
    check "$ROOT/tests/inputs/$rel" "$OUT/${rel%.a}.tc"
done
check "$ROOT/tests/analysis/stmt_cases.a" "$ROOT/tests/analysis/stmt_cases.tc"
check "$ROOT/tests/analysis/stmt_crash_cases.a" "$ROOT/tests/analysis/stmt_crash_cases.tc"
rm -rf "$BUILD"
echo "wrote $OUT"
