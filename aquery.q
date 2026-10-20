/ aquery.q - entry point of the AQuery compiler written in q (runs on L).

/ Load it to get every compiler stage written so far:
/   bin/l_m64 aquery.q                    load, then stay in the L prompt
/   bin/l_m64 aquery.q -lex file.a        print the tokens of file.a, exit

/ Version 1 contains only the lexer (src/parse/). Later versions add the
/ parser, AST, analysis, optimisation and code generation stages here, in
/ that order.

/ Other scripts (e.g. the tests) can load this file with \l. They should set
/ .aqc.root to the folder containing aquery.q first, because .z.f (the path
/ of the running script) then names their own file, not this one.


/ The folder this file is in, as a string ("." when run from that folder).
if[not `root in key `.aqc;
  parts:"/" vs string .z.f;
  .aqc.root:$[1 = count parts; "."; -1 _ raze {x,"/"} each -1 _ parts]];

/ loadFile[relativePath]
/   Load a q file given relative to .aqc.root.
.aqc.loadFile:{[relativePath] system "l ",.aqc.root,"/",relativePath};

/ Stage 1: lexer.
.aqc.loadFile "src/parse/util.q";
.aqc.loadFile "src/parse/keywords.q";
.aqc.loadFile "src/parse/jdate.q";
.aqc.loadFile "src/parse/lex.q";


/ Command line: "-lex <file>" prints the file's tokens, one per line, in
/ the same format as tests/lexer/golden/*.tok, then exits.
if[(2 = count .z.x) and "-lex" ~ first .z.x;
  -1 each .aqc.lex.lexFile .z.x 1;
  exit 0];
