/ gen.q - q code for a whole program: the compiler's -c.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/codegen/
/ KdbGenerator.scala: genTopLevel, getPrelude and generate.

/ WHAT THE OUTPUT LOOKS LIKE
/ Exactly what `aquery.jar -c` prints:
/     <all of src/runtime/base.q, the runtime the code needs>
/     // Translation begins here
/     <statement 1>
/     <blank line>
/     <statement 2>
/     ...
/ A query becomes a q function .aq.qN, defined and then called at once:
/     .aq.q0:{
/      .aq.initQueryState[];
/      aq__t0:.aq.initTable[t;"t";0b];
/      ...
/      aq__t0
/      };
/     .aq.q0[]

/ A statement topLevel does not know signals "codegen: not supported yet:
/ NAME" (none are left after version 4 milestone 4).


/ The text of src/runtime/base.q, read once when this file is loaded
/ (Scala: getPrelude, which joins the lines with "\n", so there is no "\n"
/ after the last line).
.aqc.gen.prelude:.aqc.gen.join["\n"; read0 hsym `$.aqc.root,"/src/runtime/base.q"];

/ topLevel[x]
/   PUBLIC. The q code for one top-level statement (Scala: genTopLevel).
.aqc.gen.topLevel:{[x]
  n:.aqc.nodes.name x;
  if[n = `Query;
    id:.aqc.gen.get `queryId;
    .aqc.gen.set[`queryId; id + 1];
    code:.aqc.gen.query x;
    qName:".aq.q",string id;
    :qName,":{\n",code,"\n };\n",qName,"[]"];
  if[n = `VerbatimCode; :"// verbatim code\n",.aqc.gen.str x`c];
  / the other statements, in src/codegen/stmt.q
  if[n = `Create; :.aqc.gen.createStmt x];
  if[n = `Insert; :.aqc.gen.insertStmt x];
  if[n = `Update; :.aqc.gen.updateStmt x];
  if[n = `Delete; :.aqc.gen.deleteStmt x];
  if[n = `Load; :.aqc.gen.loadStmt x];
  if[n = `Save; :.aqc.gen.saveStmt x];
  if[n = `UDF; :.aqc.gen.udf x];
  / triggers, in src/codegen/trigger.q
  if[n = `Trigger; :.aqc.gen.trigger x];
  if[n = `DropTrigger; :.aqc.gen.dropTrigger x];
  '"codegen: not supported yet: ",string n};

/ program[prog]
/   PUBLIC. The q code for a parsed program (a list of statements), without
/   base.q: each statement starts from a clean state (only the query
/   number carries over) and the statements are separated by a blank line.
.aqc.gen.program:{[prog]
  .aqc.gen.st:.aqc.gen.fresh[];
  parts:();
  k:0;
  while[k < count prog;
    .aqc.gen.cleanTopEnv[];
    parts,:enlist .aqc.gen.topLevel prog k;
    k+:1];
  .aqc.gen.join["\n\n"; parts]};

/ generate[prog]
/   PUBLIC. The whole output of -c for a parsed program (Scala: generate):
/   base.q, the "Translation begins here" line, the program's code, and a
/   final "\n".
.aqc.gen.generate:{[prog]
  code:.aqc.gen.program prog;
  .aqc.gen.prelude,"\n// Translation begins here\n",code,"\n"};

/ parseText[text]
/   The parsed program in text, after normalising its line breaks as the
/   jar does; signals the parser's message if text does not parse.
.aqc.gen.parseText:{[text]
  r:.aqc.parse.parseRule[.aqc.parse.program; .aqc.util.normalizeLines text];
  if[not r`ok; '"parse error at ",(string r`line),":",(string r`col),": ",r`msg];
  r`node};

/ compile[text]
/   PUBLIC. The q code for the AQuery program in text, without base.q.
/   For trying the compiler at the L prompt:
/     .aqc.compile "SELECT a FROM t WHERE a > 1"
/   (-1 .aqc.compile "..." prints it on several lines.)
.aqc.compile:{[text] .aqc.gen.program .aqc.gen.parseText text};

/ compileFile[path]
/   PUBLIC. What `aquery.q -compile path` prints, as lines: the full output, or
/   (if the file does not parse) one line "FAILURE<TAB>line:col<TAB>message"
/   like -parse.
.aqc.gen.compileFile:{[path]
  text:.aqc.util.normalizeLines .aqc.util.readFile path;
  r:.aqc.parse.parseRule[.aqc.parse.program; text];
  if[not r`ok;
    :enlist "FAILURE\t",(string r`line),":",(string r`col),"\t",.aqc.ast.escape r`msg];
  .aqc.gen.lines .aqc.gen.generate r`node};

/ lines[text]
/   text split at each "\n", without the "\n"s; a final "\n" does not
/   start another (empty) line. The same result as .aqc.dot.lines, but
/   without a loop over every character, which is slow in L for the 22 KB
/   of base.q.
/     lines "a\n\nb\n"   is ("a";"";"b")
.aqc.gen.lines:{[text]
  if[not "\n" ~ last text; text,:"\n"];
  ends:where "\n" = text;          / where each line break is
  starts:0,1 + -1 _ ends;          / each line starts after the previous break
  pieces:starts cut text;          / each line with its "\n"
  -1 _' pieces};                   / _' drops the "\n" from each piece
