#!/bin/sh
# probe.sh: read-only experiments for the v5 (runtime + \aq console) plan.
# Run from the aquery-q folder:   sh <this folder>/probe.sh > /tmp/aq_probe.txt 2>&1
# Writes only to /tmp. Changes nothing in the repo.
L=bin/l_m64
P=$(cd "$(dirname "$0")" && pwd)
INPUT='1+1
\aq SELECT a FROM t
2+2
'
echo "== A: unknown backslash command, no hook defined (pipe)"
printf '%s' "$INPUT" | $L
echo "== B: .z.pi console hook (pipe)"
printf '%s' "$INPUT" | $L "$P/probe_zpi.q"
echo "== B2: .z.pi console hook (real terminal via script)"
printf '%s' "$INPUT" > /tmp/aq_probe_input.txt
script -q /dev/null $L "$P/probe_zpi.q" < /tmp/aq_probe_input.txt
echo "== C: language prefixes aq) and s) with .aq.e and .s.e"
printf 'aq)SELECT a FROM t\ns)SELECT b FROM t\n2+2\n' | $L "$P/probe_lang.q"
echo "== D: base.q with the cols parameter renamed to cs"
sed -e 's/{\[tbl;cols\]/{[tbl;cs]/' -e 's/\.trg\.symCode cols\]/.trg.symCode cs]/' src/runtime/base.q > /tmp/aq_base_l.q
diff src/runtime/base.q /tmp/aq_base_l.q
$L "$P/probe_base.q" < /dev/null
echo "== E: compile and run queries"
$L "$P/probe_run.q" < /dev/null
echo "== done"
