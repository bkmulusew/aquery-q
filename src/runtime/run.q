/ run.q - run AQuery text inside L and get the result back.

/ The compiler (src/parse, src/codegen) turns AQuery text into q code.
/ This file runs that q code in the same L process, so a query reads and
/ changes your ordinary global tables:
/     t:([] a:1 2 3; b:10 20 30)
/     .aqc.run "SELECT a, b FROM t WHERE a > 1"
/   returns the table ([] a:2 3; b:20 30).

/ It needs the runtime library loaded first: src/runtime/base_l.q, the copy
/ of base.q that L can load (aquery.q loads both).

/ HOW THE CODE IS RUN
/ The q code for a whole program (.aqc.compile) is meant to be loaded as a
/ script with \l. In a script, a line that starts in the first column
/ begins a new q statement, and a line that starts with a blank continues
/ the one before (that is how a function can span several lines).
/ `value` reads a string differently: a line break is just a blank, so
/   value ".aq.insert[`s;s;();x]\n.aq.insert[`s;s;();y]"
/ reads one expression and fails with 'type. So .aqc.run cuts each
/ statement's code into script statements first (scriptStatements below)
/ and gives them to `value` one at a time.


/ The q code of the last program .aqc.run ran, for looking at what a query
/ became:   -1 .aqc.lastCode
.aqc.lastCode:"";

/ scriptStatements[code]
/   The q statements in code, cut the way \l cuts a script: a line that
/   starts with something other than a blank begins a new statement, a line
/   that starts with a blank continues the current one. Empty lines and
/   comment lines (starting with "/") are left out.
/   (Not handled: a "/" alone on a line, which in a script opens a block
/   comment. The code generator never writes one.)
/     scriptStatements "f:{\n x+1\n };\n// note\n\nf 2"
/   is ("f:{\n x+1\n };"; "f 2").
.aqc.rt.scriptStatements:{[code]
  codeLines:.aqc.gen.lines (),code;      / (), makes a one-character code a string
  isEmpty:0 = count each codeLines;
  isComment:{[line] "/" ~ first line} each codeLines;
  kept:codeLines where not isEmpty or isComment;
  if[0 = count kept; :()];
  startsAtLeft:{[line] not (first line) in " \t"} each kept;
  starts:distinct 0,where startsAtLeft;   / the first line always starts one
  / (), keeps a one-character statement a string, not a character atom
  {[part] (),.aqc.gen.join["\n"; part]} each starts cut kept};

/ run[text]
/   PUBLIC. Compile the AQuery program in text and run it, one statement
/   at a time. Returns the result of the last statement (for a SELECT, the
/   result table).
/   Signals "parse error at line:col: message" if text does not parse; a q
/   error while running a statement is signalled as it is. Empty text
/   (or only blanks) returns :: (nothing).
/     .aqc.run "CREATE TABLE s (id INT)\nINSERT INTO s VALUES(1)\nSELECT * FROM s"
/   creates the global table s, inserts a row, and returns ([] id:enlist 1).
.aqc.run:{[text]
  / The parser needs at least one statement, so text that is empty or only
  / blanks is not passed to it: there is nothing to run.
  if[all text in " \t\r\n"; :(::)];
  codes:.aqc.gen.statements .aqc.gen.parseText text;
  .aqc.lastCode:.aqc.gen.join["\n\n"; codes];
  pieces:raze .aqc.rt.scriptStatements each codes;
  result:(::);                     / no result until a statement runs
  k:0;
  while[k < count pieces;
    result:value pieces k;         / value runs q code given as a string
    k+:1];
  result};

/ runFile[path]
/   PUBLIC. .aqc.run on the contents of an AQuery file.
/     .aqc.runFile "examples/query.a"
.aqc.runFile:{[path] .aqc.run .aqc.util.readFile path};
