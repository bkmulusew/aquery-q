/ test_dot.q - check the -p graph (src/ast/dot.q) against the original
/ compiler.

/ tools/gen_dot_golden.sh ran `aquery.jar -p` on every input that the jar
/ can parse and saved the graph in tests/ast/golden/<path>.dot. This file
/ makes the graph of the same input with the q compiler and checks every
/ line is identical. Inputs listed in tests/ast/divergences.txt are
/ skipped. A second check makes sure no golden file is missing: every input
/ that parses (its parser golden file is a tree) must have a graph.

/ Run from the aquery-q folder:   bin/l_m64 tests/ast/test_dot.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The input for a golden file: "tests/ast/golden/financial/Q1.dot" ->
/ "tests/inputs/financial/Q1.a" (.test.inputFor in tests/lib/testing.q)
inputFor:.test.inputFor["tests/ast/golden"];

goldens:.test.findFiles["tests/ast/golden"; ".dot"];
-1 "golden files: ",string count goldens;
skipped:.test.skippedInputs "tests/ast/divergences.txt";
checked:goldens where not (inputFor each goldens) in skipped;
-1 "skipped (listed in tests/ast/divergences.txt): ",string (count goldens) - count checked;

i:0;
while[i < count checked;
  goldenPath:checked i;
  inputPath:inputFor goldenPath;
  .test.checkLines[inputPath; .aqc.dot.graphFile inputPath; read0 hsym `$goldenPath];
  i+:1];


/ Every input whose parser golden file is a tree (not FAILURE) parses, so
/ the jar printed a graph for it and it must have a .dot golden file.
parsed:();
astFiles:.test.findFiles["tests/parser/golden"; ".ast"];
i:0;
while[i < count astFiles;
  firstLine:first read0 hsym `$astFiles i;
  if[not "FAILURE" ~ 7 # firstLine;
    parsed,:enlist .test.inputFor["tests/parser/golden"; astFiles i]];
  i+:1];

withGraph:inputFor each goldens;

.test.check["every input that parses has a graph golden file"; asc parsed; asc withGraph];

.test.finish[];
