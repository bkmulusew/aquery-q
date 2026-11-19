#!/bin/sh
# test_cli.sh - check "aquery.q -tc" on the command line, which should
# behave like "aquery.jar -tc".
#
# Usage (from anywhere):   sh tests/analysis/test_cli.sh
# Exit status: 0 if every check passed, 1 otherwise.
#
# 1. A file with type errors: the errors, one per line, exactly as the jar
#    prints them (tests/analysis/stmt_cases.tc without its "ERROR<TAB>"),
#    no q code, and exit status 1.
# 2. A file without type errors: the same q code as without -tc, exit
#    status 0. "-tc file" alone compiles too, as with the jar.

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT" || exit 1
TMP=${TMPDIR:-/tmp}/aqc_cli.$$
mkdir -p "$TMP"
status=0

# 1.
bin/l_m64 aquery.q -compile -tc tests/analysis/stmt_cases.a > "$TMP/errors.out" 2>&1 < /dev/null
code=$?
sed 's/^ERROR	//' tests/analysis/stmt_cases.tc > "$TMP/errors.expected"
if [ "$code" = 1 ] && cmp -s "$TMP/errors.out" "$TMP/errors.expected"; then
    echo "passed: -tc prints the type errors and stops"
else
    echo "FAIL: -tc on stmt_cases.a (exit status $code)"
    diff "$TMP/errors.expected" "$TMP/errors.out" | head -10
    status=1
fi

# 2.
bin/l_m64 aquery.q -tc tests/inputs/resources/simple.a > "$TMP/tc.out" 2>&1 < /dev/null
code=$?
bin/l_m64 aquery.q -compile tests/inputs/resources/simple.a > "$TMP/plain.out" 2>&1 < /dev/null
if [ "$code" = 0 ] && cmp -s "$TMP/tc.out" "$TMP/plain.out"; then
    echo "passed: -tc on a file without errors compiles it"
else
    echo "FAIL: -tc on simple.a (exit status $code)"
    diff "$TMP/plain.out" "$TMP/tc.out" | head -10
    status=1
fi

rm -rf "$TMP"
[ "$status" = 0 ] && echo "cli: all passed"
exit $status
