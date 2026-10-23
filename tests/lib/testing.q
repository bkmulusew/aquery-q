/ testing.q - a very small test library.

/ Usage in a test file:
/   .test.check["what is being tested"; actual; expected];
/   ...
/   .test.finish[];      / prints a summary and exits (status 1 on failure)

/ Each check compares with ~ (q's "match": same type, same shape, same
/ values). Failures are printed straight away with both values.


/ Counters, reset when this file is loaded.
.test.passed:0;
.test.failed:0;
.test.failedNames:();


/ show[x]
/   A one-line printable form of any value, for failure messages.
.test.show:{[x] .Q.s1 x};


/ check[name; actual; expected]
/   Record one test result.
/   name:     string describing the test
/   actual:   the value the code produced
/   expected: the value it should have produced
/   returns:  1b if they match
.test.check:{[name;actual;expected]
  ok:actual ~ expected;
  $[ok;
    .test.passed+:1;
    [.test.failed+:1;
     .test.failedNames,:enlist name;
     -1 "FAIL: ",name;
     -1 "  expected: ",.test.show expected;
     -1 "  actual:   ",.test.show actual]];
  ok};


/ checkLines[name; actual; expected]
/   Like check, for two lists of strings (e.g. lines of output). On a
/   mismatch it prints only the first line that differs, which is much
/   easier to read than two whole lists.
.test.checkLines:{[name;actual;expected]
  ok:actual ~ expected;
  $[ok;
    .test.passed+:1;
    [.test.failed+:1;
     .test.failedNames,:enlist name;
     i:0;
     while[(i < count actual) and (i < count expected) and (actual i) ~ expected i; i+:1];
     -1 "FAIL: ",name;
     -1 "  first difference at line ",string 1 + i;
     -1 "  expected: ",$[i < count expected; expected i; "<no more lines>"];
     -1 "  actual:   ",$[i < count actual; actual i; "<no more lines>"]]];
  ok};


/ findFiles[dir; suffix]
/   All files under dir (searched recursively) whose name ends with suffix.
/   dir:     string, e.g. "tests/lexer/golden"
/   suffix:  string, e.g. ".tok"
/   returns: list of paths (strings), sorted
.test.findFiles:{[dir;suffix]
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
      found,:.test.findFiles[path;suffix];
      if[suffix ~ (neg count suffix)#path; found,:enlist path]];
    i+:1];
  asc found};


/ inputFor[goldenDir; goldenPath]
/   The test input that a golden file was made from: the same path under
/   tests/inputs, ending in ".a" instead of the golden file's ending.
/     inputFor["tests/parser/golden"; "tests/parser/golden/financial/Q1.ast"]
/       is "tests/inputs/financial/Q1.a"
.test.inputFor:{[goldenDir;goldenPath]
  relative:(1 + count goldenDir) _ goldenPath;   / 1 + for the "/" after goldenDir
  dot:last where "." = relative;                 / where the ending starts
  "tests/inputs/",(dot#relative),".a"};


/ skippedInputs[path]
/   The inputs listed in a divergences.txt file (see tests/lexer/ and
/   tests/parser/): the first word of every line that is not blank and not
/   a "#" comment.
/   returns: list of input paths, e.g. "tests/inputs/edge_cases/x.a"
.test.skippedInputs:{[path]
  lines:read0 hsym `$path;
  words:{first " " vs x} each lines;
  words:words where (0 < count each words) and not "#" = first each words;
  {"tests/inputs/",x} each words};


/ positionOnly[lines]
/   Parser output lines with the message dropped from a failure, which is
/   all the parser tests compare for a failure (tests/parser/README.md):
/     ("FAILURE<TAB>1:5<TAB>msg")  ->  ("FAILURE<TAB>1:5")
/   A tree is returned as it is.
.test.positionOnly:{[lines]
  if[not "FAILURE\t" ~ 8 # first lines; :lines];
  enlist "\t" sv 2 # "\t" vs first lines};


/ finish[]
/   Print "N passed, M failed" and exit the L process:
/   exit status 0 if every check passed, 1 otherwise.
.test.finish:{[]
  -1 (string .test.passed)," passed, ",(string .test.failed)," failed";
  exit $[.test.failed > 0; 1; 0]};
