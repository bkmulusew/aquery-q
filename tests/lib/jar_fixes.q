/ jar_fixes.q - turn the jar's output into the output of the fixed code
/ generator, for jar bugs that touch many golden files.

/ Most jar bugs we fixed touch only a few golden files, which are then
/ skipped (tests/codegen/divergences.txt). Bug 5, found in version 5, is in
/ every string literal (26 programs and many expression goldens), so
/ instead of skipping all of them the tests fix the expected text the same
/ way the code generator does, and still compare everything else.


/ stringLits[quote; line]
/   Bug 5 fixed in one line of jar output: every `$<quote>text<quote>
/   (a string literal) becomes (enlist `$<quote>text<quote>), as
/   .aqc.gen.lit writes it now. Not changed: a file name after "hsym "
/   (LOAD and SAVE write hsym `$"f.csv", which is plain q code, not part
/   of a parse tree).
/   quote is "\"" for q code, and "\\\"" for the escaped code in
/   tests/codegen/expr_golden/ (where a " is written \").
/   (The text of a string literal never contains a ", see .aqc.gen.lit.)
/     stringLits["\""; "(=; a; `$\"IBM\")"]   is   "(=; a; (enlist `$\"IBM\"))"
/     stringLits["\""; "hsym `$\"f.csv\""]     is   "hsym `$\"f.csv\"" (unchanged)
.jarFix.stringLits:{[quote; line]
  open:"`$",quote;           / how a string literal starts
  done:"";                   / the fixed part of the line
  rest:line;                 / what is still to be looked at
  while[1b;
    found:rest ss open;      / where each literal starts in rest
    if[0 = count found; :done,rest];
    i:first found;
    afterOpen:i + count open;
    closeAt:afterOpen + first (afterOpen _ rest) ss quote;
    stop:closeAt + count quote;          / just after the literal
    literal:(stop - i) # i _ rest;
    before:done,i # rest;                / everything up to the literal
    $["hsym " ~ -5 # before;
      done:before,literal;
      done:before,"(enlist ",literal,")"];
    rest:stop _ rest]};
