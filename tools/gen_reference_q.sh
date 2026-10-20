#!/bin/sh
# gen_reference_q.sh: record what the original Scala compiler produces.
#
# For every tests/inputs/<path>.a this runs tools/aquery.jar and writes
#   tests/reference_q/<path>.q          compiled q code, no optimisation (-a 0)
#   tests/reference_q/<path>.opt.q      compiled q code, optimised     (-a 1)
# or, when the jar cannot parse the input (many Scala test snippets are
# single expressions, not whole programs):
#   tests/reference_q/<path>.error.txt  the jar's error message
#
# The jar prints src/runtime/base.q followed by the translated program.
# To avoid storing 21 KB of identical base.q in every file, only the part
# from the line "// Translation begins here" onwards is kept. The script
# checks that the part it removes is exactly src/runtime/base.q, so
#     cat src/runtime/base.q tests/reference_q/<path>.q
# is byte-for-byte the jar's original output.
#
# These files are not used by version 1 (the lexer). They are the expected
# results for the code-generation stage in a later version.
#
# Usage (from anywhere):   sh tools/gen_reference_q.sh
# Takes several minutes: the JVM starts twice per input.

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR="$ROOT/tools/aquery.jar"
BASE="$ROOT/src/runtime/base.q"
INPUTS="$ROOT/tests/inputs"
OUT="$ROOT/tests/reference_q"
BASE_BYTES=$(wc -c < "$BASE" | tr -d ' ')

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# start clean, but keep the folder's README.md
mkdir -p "$OUT"
find "$OUT" -type f ! -name README.md -delete

# compile <input .a> <optimisation level> <output .q>
# Writes the translated part of the jar's output, or an .error.txt file.
compile() {
    java -jar "$JAR" -c -s -a "$2" "$1" > "$TMP/full.q"
    if grep -q '^// Translation begins here$' "$TMP/full.q"; then
        # the first BASE_BYTES bytes must be base.q, unchanged
        head -c "$BASE_BYTES" "$TMP/full.q" > "$TMP/prefix.q"
        if ! cmp -s "$TMP/prefix.q" "$BASE"; then
            echo "ERROR: output of $1 does not start with base.q" >&2
            exit 1
        fi
        tail -c +"$((BASE_BYTES + 1))" "$TMP/full.q" > "$3"
        return 0
    else
        cp "$TMP/full.q" "${3%.q}.error.txt"
        return 1
    fi
}

compiled=0
errors=0
for input in $(cd "$INPUTS" && find . -name '*.a' | sort); do
    rel=${input#./}
    dest="$OUT/${rel%.a}"
    mkdir -p "$(dirname "$dest")"
    if compile "$INPUTS/$rel" 0 "$dest.q"; then
        compile "$INPUTS/$rel" 1 "$dest.opt.q" || true
        compiled=$((compiled + 1))
    else
        errors=$((errors + 1))
    fi
done

echo "compiled: $compiled, not parseable by the jar: $errors"
