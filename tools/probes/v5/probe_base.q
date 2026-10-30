/ 1. Load the renamed base.q with \l and see whether it gets to the end.
r:@[{system "l ",x; `ok}; "/tmp/aq_base_l.q"; {`$"FAILED: ",x}];
-1 "whole-file load: ",string r;
-1 ".aq names: ",string count key `.aq;
-1 ".trg names: ",string count key `.trg;
/ 2. Evaluate it one top-level definition at a time, to list every failure.
lines:read0 `:/tmp/aq_base_l.q;
isStart:{[l] $[0 = count l; 0b; not (first l) in " \t}"]} each lines;
starts:where isStart;
chunks:starts cut lines;
evalChunk:{[c] @[{value "\n" sv x; `ok}; c; {`$x}]};
results:evalChunk each chunks;
bad:where not results = `ok;
-1 "top-level chunks: ",string count chunks;
-1 "failing chunks: ",string count bad;
{[i] -1 "  line ",(string 1 + starts i),": ",(string results i)," | ",80 sublist first chunks i} each bad;
exit 0
