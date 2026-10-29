/ aquery.q - entry point of the AQuery compiler written in q (runs on L).

/ Load it to get every compiler stage written so far:
/   bin/l_m64 aquery.q                    load, then stay in the L prompt
/   bin/l_m64 aquery.q -lex file.a        print the tokens of file.a, exit
/   bin/l_m64 aquery.q -parse file.a      print the parse tree of file.a, exit
/   bin/l_m64 aquery.q -p file.a          print file.a as a Graphviz graph, exit
/   bin/l_m64 aquery.q -compile file.a    print the q code for file.a, exit
/   bin/l_m64 aquery.q -compile -out out.q file.a
/                                         write the q code for file.a to out.q

/ Version 1 is the lexer, version 2 the parser (both in src/parse/),
/ version 3 the AST stage (src/ast/), version 4 code generation
/ (src/codegen/). Later versions add the runtime, and analysis and
/ optimisation here.

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

/ Stage 4: code generation (parse tree -> q code), version 4.
.aqc.loadFile "src/codegen/state.q";
.aqc.loadFile "src/codegen/expr.q";
.aqc.loadFile "src/codegen/plan.q";
.aqc.loadFile "src/codegen/stmt.q";
.aqc.loadFile "src/codegen/trigger.q";
.aqc.loadFile "src/codegen/gen.q";


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

/ Command line: "-compile [-silent] [-a 0] [-out out.q] <file>" compiles
/ the file to q code, exactly as `aquery.jar -c` does, and prints it (or
/ writes it to out.q), then exits. Options are read in any order; the file
/ comes last.
/ (-compile, not -c: L reads -c itself, as q's console size.)
/ (-out and -silent, not the jar's -o and -s: L reads those too, as q's
/ UTC offset and secondary threads.)
/ The optimizer (-a 1, -opts) and type checking (-tc) come in version 6,
/ so they stop with a message instead of silently doing nothing.
/ (The arguments are compared as symbols: "-compile" in .z.x would test
/ each character of "-compile" on its own.)
if[(`$"-compile") in `$.z.x;
  .aqc.cli.args:.z.x;
  .aqc.cli.out:"";
  .aqc.cli.input:"";
  k:0;
  while[k < count .aqc.cli.args;
    a:`$.aqc.cli.args k;
    $[a = `$"-out"; [.aqc.cli.out:.aqc.cli.args k + 1; k+:1];
      a = `$"-a";
        [if[not "0" ~ .aqc.cli.args k + 1;
           -2 "-a ",(.aqc.cli.args k + 1),": optimizer not supported until v6";
           exit 1];
         k+:1];
      a in `$("-opts";"-tc"); [-2 (string a),": not supported until v6"; exit 1];
      a in `$("-compile";"-silent"); ::;
      .aqc.cli.input:.aqc.cli.args k];
    k+:1];
  .aqc.cli.lines:.aqc.gen.compileFile .aqc.cli.input;
  $[0 = count .aqc.cli.out; -1 each .aqc.cli.lines; (hsym `$.aqc.cli.out) 0: .aqc.cli.lines];
  exit 0];
