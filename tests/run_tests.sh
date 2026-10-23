#!/bin/sh
# run_tests.sh: run every test of the q AQuery compiler in L.
#
# Usage (from anywhere):   sh tests/run_tests.sh
# Exit status: 0 if every test file passed, 1 otherwise.
#
# Each test file is a q script that prints its own results and exits with
# status 0 (all passed) or 1 (something failed). Add new test files to the
# list below as later versions add stages (parser, ast, ...).

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

TEST_FILES="
tests/lexer/test_lexer.q
tests/lexer/test_golden.q
tests/parser/test_parser.q
tests/parser/test_rules.q
tests/parser/test_golden.q
"

status=0
for t in $TEST_FILES; do
    echo "== $t"
    # </dev/null: if a script stops early, L would otherwise wait for input
    if ! bin/l_m64 "$t" < /dev/null; then
        status=1
    fi
done

if [ "$status" -eq 0 ]; then
    echo "ALL TESTS PASSED"
else
    echo "SOME TESTS FAILED"
fi
exit "$status"
