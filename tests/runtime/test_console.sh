#!/bin/sh
# test_console.sh - check the \aq console (src/runtime/console.q) by
# typing lines into L, the way a person would.
#
# Usage (from anywhere):   sh tests/runtime/test_console.sh
# Exit status: 0 if every check passed, 1 otherwise.
#
# 1. Plain q lines (console/q_lines.txt) must print exactly what L's own
#    console prints for them, with and without the hook.
# 2. An AQuery session (console/aq_session.txt) must print
#    console/aq_session.expected.
# 3. In a real terminal (driven by expect, console/terminal.exp), \aq
#    must print its result.

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT" || exit 1
DIR=tests/runtime/console
TMP=${TMPDIR:-/tmp}/aqc_console.$$
mkdir -p "$TMP"
status=0

# An error line carries the time ('2026.10.29T10:56:44.333 type), which is
# different on every run; replace it with TIME so outputs can be compared.
normalize() {
    sed -E "s/'[0-9]{4}\.[0-9]{2}\.[0-9]{2}T[0-9:.]+ /'TIME /g"
}

# 1. q lines: L alone, then L with aquery.q (and so the hook) loaded.
bin/l_m64 < "$DIR/q_lines.txt" 2>&1 | normalize > "$TMP/q_plain.out"
bin/l_m64 aquery.q < "$DIR/q_lines.txt" 2>&1 | normalize > "$TMP/q_hook.out"
if cmp -s "$TMP/q_plain.out" "$TMP/q_hook.out"; then
    echo "passed: q lines print as in L's own console"
else
    echo "FAIL: q lines print differently with the hook (< L alone, > with the hook):"
    diff "$TMP/q_plain.out" "$TMP/q_hook.out"
    status=1
fi

# 2. The AQuery session.
bin/l_m64 aquery.q < "$DIR/aq_session.txt" 2>&1 | normalize > "$TMP/aq.out"
if [ ! -f "$DIR/aq_session.expected" ]; then
    echo "FAIL: no $DIR/aq_session.expected yet; the session printed:"
    cat "$TMP/aq.out"
    status=1
elif cmp -s "$DIR/aq_session.expected" "$TMP/aq.out"; then
    echo "passed: AQuery session"
else
    echo "FAIL: AQuery session (< expected, > actual):"
    diff "$DIR/aq_session.expected" "$TMP/aq.out"
    status=1
fi

# 3. A real terminal.
if command -v expect > /dev/null; then
    if ! expect "$DIR/terminal.exp"; then
        status=1
    fi
else
    echo "skipped: expect is not installed, no real-terminal check"
fi

rm -rf "$TMP"
if [ "$status" -eq 0 ]; then echo "console: all passed"; else echo "console: SOME FAILED"; fi
exit "$status"
