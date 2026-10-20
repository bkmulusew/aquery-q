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


/ finish[]
/   Print "N passed, M failed" and exit the L process:
/   exit status 0 if every check passed, 1 otherwise.
.test.finish:{[]
  -1 (string .test.passed)," passed, ",(string .test.failed)," failed";
  exit $[.test.failed > 0; 1; 0]};
