/ test_golden.q - compare the q lexer with the original Scala lexer.

/ For every golden file tests/lexer/golden/<path>.tok (made by
/ tools/gen_golden.sh from tools/aquery.jar) lex tests/inputs/<path>.a
/ with the q lexer and check the output is identical, line for line.

/ Run from the aquery-q folder:   bin/l_m64 tests/lexer/test_golden.q


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ findFiles[dir; suffix]
/   All files under dir (searched recursively) whose name ends with suffix.
/   dir:     string, e.g. "tests/lexer/golden"
/   suffix:  string, e.g. ".tok"
/   returns: list of paths (strings), sorted
.goldenTest.findFiles:{[dir;suffix]
  found:();
  entries:key hsym `$dir;
  / key on a file returns the file's own name (a symbol atom);
  / key on a folder returns the list of names inside it
  if[-11h = type entries; :()];
  i:0;
  while[i < count entries;
    path:dir,"/",string entries i;
    inside:key hsym `$path;
    $[11h = type inside;
      found,:.goldenTest.findFiles[path;suffix];
      if[suffix ~ (neg count suffix)#path; found,:enlist path]];
    i+:1];
  asc found};


/ inputFor[goldenPath]
/   "tests/lexer/golden/financial/Q1.tok" -> "tests/inputs/financial/Q1.a"
.goldenTest.inputFor:{[goldenPath]
  prefix:"tests/lexer/golden/";
  relative:(count prefix) _ goldenPath;
  "tests/inputs/",(-4 _ relative),".a"};


goldenFiles:.goldenTest.findFiles["tests/lexer/golden";".tok"];
-1 "golden files: ",string count goldenFiles;

i:0;
while[i < count goldenFiles;
  goldenPath:goldenFiles i;
  inputPath:.goldenTest.inputFor goldenPath;
  .test.checkLines[inputPath;.aqc.lex.lexFile inputPath;read0 hsym `$goldenPath];
  i+:1];

.test.finish[];
