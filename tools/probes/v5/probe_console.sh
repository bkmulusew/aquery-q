#!/bin/sh
# Run from aquery-q: how L's own console prints each line of console_lines.txt
P=$(cd "$(dirname "$0")" && pwd)
echo "== default console"
bin/l_m64 < "$P/console_lines.txt"
echo "== parse"
bin/l_m64 "$P/probe_parse.q" < /dev/null
echo "== done"
