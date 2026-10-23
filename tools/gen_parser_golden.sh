#!/bin/sh
# gen_parser_golden.sh: regenerate the golden (expected) parser output.
#
# For every AQuery file tests/inputs/<path>.a this writes
# tests/parser/golden/<path>.ast, the parse tree (or the failure) produced
# by the original Scala parser in tools/aquery.jar (see tools/AstDump.java
# for the file format).
#
# Usage (from anywhere):   sh tools/gen_parser_golden.sh
# Needs: a JDK 11 or newer (javac + java). Nothing is installed or changed
# outside this folder; AstDump is compiled into a temporary directory.

set -eu

# Folder layout, relative to this script.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR="$ROOT/tools/aquery.jar"
INPUTS="$ROOT/tests/inputs"
GOLDEN="$ROOT/tests/parser/golden"

# 1. Compile AstDump.java against the jar, into a temp dir removed on exit.
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
javac -cp "$JAR" -d "$BUILD" "$ROOT/tools/AstDump.java"

# 2. Start from an empty golden folder so deleted inputs leave no stale files.
rm -rf "$GOLDEN"
mkdir -p "$GOLDEN"

# 3. Run AstDump on each input. Paths are kept relative to tests/inputs,
#    so tests/inputs/financial/Q1.a -> tests/parser/golden/financial/Q1.ast
#    A program that does not parse still gets a golden file (one FAILURE
#    line); only a crash of AstDump itself counts as a failure here.
count=0
failed=0
for input in $(cd "$INPUTS" && find . -name '*.a' | sort); do
    rel=${input#./}                       # financial/Q1.a
    out="$GOLDEN/${rel%.a}.ast"           # .../golden/financial/Q1.ast
    mkdir -p "$(dirname "$out")"
    if java -cp "$JAR:$BUILD" AstDump "$INPUTS/$rel" > "$out"; then
        count=$((count + 1))
    else
        echo "FAILED: $rel" >&2
        rm -f "$out"
        failed=$((failed + 1))
    fi
done

parsed=$(grep -L '^FAILURE' -r "$GOLDEN" | wc -l | tr -d ' ')
echo "golden files written: $count (programs that parse: $parsed), crashes: $failed"
[ "$failed" -eq 0 ]
