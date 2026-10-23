/ aquery.q - entry point of the AQuery compiler written in q (runs on L).

/ Load it to get every compiler stage written so far:
/   bin/l_m64 aquery.q                    load, then stay in the L prompt
/   bin/l_m64 aquery.q -lex file.a        print the tokens of file.a, exit
/   bin/l_m64 aquery.q -parse file.a      print the parse tree of file.a, exit
/   bin/l_m64 aquery.q -p file.a          print file.a as a Graphviz graph, exit

/ Version 1 is the lexer, version 2 the parser (both in src/parse/),
/ version 3 the AST stage (src/ast/). Later versions add code generation,
/ the runtime, and analysis and optimisation here.

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

/ Stage 2: parser (tokens -> parse tree).
.aqc.loadFile "src/parse/ast.q";
.aqc.loadFile "src/parse/parser.q";
.aqc.loadFile "src/parse/rewrite.q";

/ Stage 3: AST helpers (walking and rebuilding parse trees) and the
/ Graphviz graph of a program.
.aqc.loadFile "src/ast/nodes.q";
.aqc.loadFile "src/ast/dot.q";


/ Command line: "-lex <file>" prints the file's tokens, one per line, in
/ the same format as tests/lexer/golden/*.tok, then exits.
if[(2 = count .z.x) and "-lex" ~ first .z.x;
  -1 each .aqc.lex.lexFile .z.x 1;
  exit 0];

/ Command line: "-parse <file>" prints the file's parse tree in the same
/ format as tests/parser/golden/*.ast, then exits.
if[(2 = count .z.x) and "-parse" ~ first .z.x;
  -1 each .aqc.parse.parseFile .z.x 1;
  exit 0];

/ Command line: "-p <file>" prints the file as a Graphviz (DOT) graph,
/ exactly as the jar does (tools/gen_dot_golden.sh, tests/ast/golden/*.dot),
/ then exits. Draw it with: dot -Tpdf out.dot -o out.pdf
if[(2 = count .z.x) and "-p" ~ first .z.x;
  -1 each .aqc.dot.graphFile .z.x 1;
  exit 0];
