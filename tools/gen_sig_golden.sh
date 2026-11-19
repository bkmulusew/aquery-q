#!/bin/sh
# gen_sig_golden.sh: ask the original Scala type checker what every built-in
# function returns for every list of 0 to 3 argument types, and write the
# answers to tests/analysis/sig_golden.txt, the expected results for
# tests/analysis/test_functions.q. See tools/TypeDump.java for the format.
#
# Usage (from anywhere):   sh tools/gen_sig_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac and java). The jar defaults to tools/aquery.jar.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
OUT=$ROOT/tests/analysis/sig_golden.txt
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/TypeDump.java" || exit 1
java -cp "$JAR:$BUILD" TypeDump sigs > "$OUT" || exit 1
rm -rf "$BUILD"
echo "wrote $OUT"
