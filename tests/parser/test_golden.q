/ test_golden.q - compare the q parser with the original Scala parser on
/ whole programs.

/ For every golden file tests/parser/golden/<path>.ast (made by
/ tools/gen_parser_golden.sh from tools/aquery.jar) parse
/ tests/inputs/<path>.a with the q parser and check the output is the
/ same, line for line. For a program that does not parse, only the
/ position of the failure is compared (see tests/parser/README.md).

/ Run from the aquery-q folder:   bin/l_m64 tests/parser/test_golden.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The input for a golden file: "tests/parser/golden/financial/Q1.ast" ->
/ "tests/inputs/financial/Q1.a" (.test.inputFor in tests/lib/testing.q)
inputFor:.test.inputFor["tests/parser/golden"];


goldenFiles:.test.findFiles["tests/parser/golden";".ast"];
-1 "golden files: ",string count goldenFiles;
skipped:.test.skippedInputs "tests/parser/divergences.txt";
checked:goldenFiles where not (inputFor each goldenFiles) in skipped;
-1 "skipped (listed in tests/parser/divergences.txt): ",string (count goldenFiles) - count checked;
goldenFiles:checked;

i:0;
while[i < count goldenFiles;
  goldenPath:goldenFiles i;
  inputPath:inputFor goldenPath;
  actual:.test.positionOnly .aqc.parse.parseFile inputPath;
  expected:.test.positionOnly read0 hsym `$goldenPath;
  .test.checkLines[inputPath;actual;expected];
  i+:1];

.test.finish[];
