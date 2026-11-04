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


/ zeroArgCalls[line]
/   Fix 6 (paper test) in one line of jar output: a call with no
/   arguments, (f;) or (f';), becomes (f;()), as .aqc.gen.funCall writes
/   it now.
/     zeroArgCalls "(>=; a; (q9StartDate;))"   is   "(>=; a; (q9StartDate;()))"
.jarFix.zeroArgCalls:{[line]
  nameChars:.Q.an,".'";        / letters, digits, _ . and ' (each)
  done:"";
  rest:line;
  while[1b;
    found:rest ss ";)";
    if[0 = count found; :done,rest];
    i:first found;
    before:i # rest;
    / the name is the run of name characters just before ";)"
    nameLength:(reverse before) ? first (reverse before) except nameChars;
    nameStart:i - nameLength;
    isCall:(nameLength > 0) and "(" ~ before nameStart - 1;
    $[isCall;
      [name:nameLength # nameStart _ rest;
       if["'" ~ last name; name:-1 _ name];
       done,:(nameStart # rest),name,";())"];
      done,:before,";)"];
    rest:(i + 2) _ rest]};

/ groupedCount[line]
/   Fix 7 (paper test): COUNT(*) after GROUP BY. (.aq.count';`i) becomes
/   .aqc.gen.groupedCountStar of the line's table (the name before ":" in
/   " aq__t3:...", or aq__t0, the table the expression goldens use).
.jarFix.groupedCount:{[line]
  old:"(.aq.count';`i)";
  if[0 = count line ss old; :line];
  t:$[" aq__t" ~ 6 # line; 1 _ (line ? ":") # line; "aq__t0"];
  ssr[line; old; .aqc.gen.groupedCountStar t]};

/ apply[quote; lines]
/   Every fix above, applied to the lines of a golden file.
.jarFix.apply:{[quote; lines]
  fixed:.jarFix.stringLits[quote] each lines;
  fixed:.jarFix.zeroArgCalls each fixed;
  .jarFix.groupedCount each fixed};
