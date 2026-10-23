/ test_golden.q - compare the q lexer with the original Scala lexer.

/ For every golden file tests/lexer/golden/<path>.tok (made by
/ tools/gen_golden.sh from tools/aquery.jar) lex tests/inputs/<path>.a
/ with the q lexer and check the output is identical, line for line.

/ Run from the aquery-q folder:   bin/l_m64 tests/lexer/test_golden.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ The input for a golden file: "tests/lexer/golden/financial/Q1.tok" ->
/ "tests/inputs/financial/Q1.a" (.test.inputFor in tests/lib/testing.q)
inputFor:.test.inputFor["tests/lexer/golden"];


goldenFiles:.test.findFiles["tests/lexer/golden";".tok"];
-1 "golden files: ",string count goldenFiles;
skipped:.test.skippedInputs "tests/lexer/divergences.txt";
checked:goldenFiles where not (inputFor each goldenFiles) in skipped;
-1 "skipped (listed in tests/lexer/divergences.txt): ",string (count goldenFiles) - count checked;
goldenFiles:checked;

i:0;
while[i < count goldenFiles;
  goldenPath:goldenFiles i;
  inputPath:inputFor goldenPath;
  .test.checkLines[inputPath;.aqc.lex.lexFile inputPath;read0 hsym `$goldenPath];
  i+:1];

.test.finish[];
