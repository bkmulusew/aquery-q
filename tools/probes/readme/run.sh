#!/bin/sh
# README probe: run the README examples in L and save the output.
cd "$(dirname "$0")/../../.." || exit 1
P=tools/probes/readme
bin/l_m64 aquery.q < $P/session.txt > $P/session.out 2>&1
for f in -lex -parse -p -compile; do
  echo "== $f" ; bin/l_m64 aquery.q $f $P/q1.a 2>&1 | head -60
done > $P/cli.out
bin/l_m64 aquery.q -compile -out /tmp/q1.q $P/q1.a > $P/out_flag.out 2>&1; wc -l /tmp/q1.q >> $P/out_flag.out
sh tests/run_tests.sh > $P/tests.out 2>&1; echo "exit $?" >> $P/tests.out
echo done
