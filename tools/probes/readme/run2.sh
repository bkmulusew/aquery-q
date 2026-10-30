#!/bin/sh
cd "$(dirname "$0")/../../.." || exit 1
bin/l_m64 aquery.q < tools/probes/readme/session2.txt > tools/probes/readme/session2.out 2>&1
echo done
