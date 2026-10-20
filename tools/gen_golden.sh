#!/bin/sh
# gen_golden.sh: regenerate the golden (expected) lexer output.
#
# For every AQuery file tests/inputs/<path>.a this writes
# tests/lexer/golden/<path>.tok, the exact token stream produced by the
# original Scala lexer in tools/aquery.jar (see tools/TokenDump.java for the
# file format).
#
# Usage (from anywhere):   sh tools/gen_golden.sh
# Needs: a JDK (javac + java). Nothing is installed or changed outside
# this folder; TokenDump is compiled into a temporary directory.

set -eu

# Folder layout, relative to this script.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR="$ROOT/tools/aquery.jar"
INPUTS="$ROOT/tests/inputs"
GOLDEN="$ROOT/tests/lexer/golden"

# 1. Compile TokenDump.java against the jar, into a temp dir removed on exit.
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
javac -cp "$JAR" -d "$BUILD" "$ROOT/tools/TokenDump.java"

# 2. Start from an empty golden folder so deleted inputs leave no stale files.
rm -rf "$GOLDEN"
mkdir -p "$GOLDEN"

# 3. Run TokenDump on each input. Paths are kept relative to tests/inputs,
#    so tests/inputs/financial/Q1.a -> tests/lexer/golden/financial/Q1.tok
count=0
failed=0
for input in $(cd "$INPUTS" && find . -name '*.a' | sort); do
    rel=${input#./}                       # financial/Q1.a
    out="$GOLDEN/${rel%.a}.tok"           # .../golden/financial/Q1.tok
    mkdir -p "$(dirname "$out")"
    if java -cp "$JAR:$BUILD" TokenDump "$INPUTS/$rel" > "$out"; then
        count=$((count + 1))
    else
        echo "FAILED: $rel" >&2
        rm -f "$out"
        failed=$((failed + 1))
    fi
done

echo "golden files written: $count, failures: $failed"
[ "$failed" -eq 0 ]
