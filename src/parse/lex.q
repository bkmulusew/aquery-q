/ lex.q - the AQuery lexer: source text -> table of tokens.

/ Ported from the Scala compiler (aquery-master/src/main/scala/edu/nyu/aquery/parse/):
/   AqueryParser.scala  class AqueryLexical: the token rules and delimiters
/   AqueryTokens.scala  dates, timestamps, verbatim q code
/ plus the parts of Scala's StdLexical / Scanners library that AqueryLexical
/ inherits (whitespace, comments, error recovery).
/ Needs util.q, keywords.q and jdate.q to be loaded first.

/ Public functions:
/   .aqc.lex.tokens[src]         string -> table of tokens (kind,text,line,col)
/   .aqc.lex.formatTokens[toks]  table  -> list of strings in the format of
/                                tests/lexer/golden/*.tok
/   .aqc.lex.lexFile[path]       read a file and return its formatted tokens

/ Token kinds, named after the Scala token classes:
/   `Keyword     a keyword (SELECT, select, ...) or a delimiter (<=, (, ...)
/   `Identifier  letter or _, then letters, digits and _
/   `NumericLit  digits, optionally with a "." and more digits
/   `StringLit   text between double quotes
/   `Date        '01/02/2020', text re-printed as MM/dd/yyyy
/   `Timestamp   '01/02/2020D10:11:12', re-printed as MM/dd/yyyyDHH:mm:ss
/                (Scala makes this a StringLit; see README)
/   `Verbatim    the text between <q> and </q>
/   `ErrorToken  something that could not be lexed; text is the message
/   `EOF         a 0x1A byte in the source, and always the last row

/ HOW IT WORKS (the same as Scala)
/ Repeat until only whitespace is left:
/   1. Skip whitespace and comments.
/   2. Try the token rules (.aqc.lex.rules) in Scala's order. A rule either
/      succeeds:  `ok`kind`text`next!(1b; kind; text; where the next token may start)
/      or fails:  `ok`msg`at!(0b; message; where it gave up)
/      The first rule that succeeds gives the token.
/   3. If every rule fails, the failure that got FURTHEST into the input
/      wins (on a tie, the later rule). It becomes an ErrorToken at that
/      position, and lexing restarts one character after it.
/      So "#" gives "illegal character" (the last rule), but "!x" gives
/      "`=' expected but x found": the "!=" delimiter got one character in.
/ Positions are 0-based offsets while lexing; they become 1-based line and
/ column numbers at the end. The Scala quirks kept on purpose are listed in
/ README.md ("Scala quirks the q lexer copies on purpose").


/ ---------------------------------------------------------------------------
/ Characters
/ ---------------------------------------------------------------------------

/ Character 26 (0x1A): Scala's end-of-input marker. Reading past the end of
/ the source gives this character (see charAt), so most rules need no
/ length checks. A real 0x1A byte in the source is an EOF token.
.aqc.lex.EOFCH:"\032";

/ Characters that can start / continue an identifier. Scala also accepts
/ non-ASCII letters; every AQuery source we have is plain ASCII.
.aqc.lex.identStart:.Q.a,.Q.A,"_";            / .Q.a is "abc...z", .Q.A "ABC...Z"
.aqc.lex.identChars:.aqc.lex.identStart,.Q.n;  / .Q.n is "0123456789"

/ charAt[src; i]
/   The character at offset i, or EOFCH past the end.
/     charAt["ab"; 1]   is "b"
/     charAt["ab"; 5]   is "\032"
.aqc.lex.charAt:{[src;i] $[i < count src; src i; .aqc.lex.EOFCH]};

/ skipWhile[chars; src; i]
/   The first offset at or after i whose character is not in chars.
/   (chars never contains EOFCH, so this always stops at the end.)
/     skipWhile[.Q.n; "123ab"; 0]   is 3
.aqc.lex.skipWhile:{[chars;src;i]
  while[.aqc.lex.charAt[src;i] in chars; i+:1];
  i};

/ skipUntil[stops; src; i]
/   The first offset at or after i whose character is in stops or is
/   EOFCH (a real 0x1A byte, or the end of the source).
/     skipUntil["\n"; "ab\ncd"; 0]   is 2
.aqc.lex.skipUntil:{[stops;src;i]
  while[not .aqc.lex.charAt[src;i] in stops,.aqc.lex.EOFCH; i+:1];
  i};

/ slice[src; start; stop]
/   The characters from offset start up to (not including) stop.
/     slice["SELECT"; 1; 3]   is "EL"
.aqc.lex.slice:{[src;start;stop] src start + til stop - start};


/ ---------------------------------------------------------------------------
/ Rule results and Scala's `accept`
/ ---------------------------------------------------------------------------

/ ok[kind; text; nextPos]  a rule matched; the next token may start at nextPos
.aqc.lex.ok:{[kind;text;nextPos] `ok`kind`text`next!(1b;kind;text;nextPos)};

/ fail[msg; at]  a rule gave up at offset at
.aqc.lex.fail:{[msg;at] `ok`msg`at!(0b;msg;at)};

/ matchLength[src; i; txt]
/   How many leading characters of txt appear in src starting at offset i.
/     matchLength["<=x"; 0; "<=>"]   is 2
/     matchLength["<";   0; "<=>"]   is 1   (never counts past the end)
.aqc.lex.matchLength:{[src;i;txt]
  here:src i + til count txt;     / q gives " " for offsets past the end
  matched:(txt = here) ? 0b;      / index of the first mismatch = length of the match
  matched & 0 | (count src) - i};

/ expect[src; i; txt]
/   Scala's accept: txt must come next, at offset i. On a mismatch, fail at
/   the first wrong character with Scala's exact message.
/     expect["<=x"; 0; "<=>"]   fails at 2: "`>' expected but x found"
/     expect["<=";  0; "<=>"]   fails at 2: "end of input"
.aqc.lex.expect:{[src;i;txt]
  txt:(),txt;                     / a single char like "'" is an atom; make it a string
  k:.aqc.lex.matchLength[src;i;txt];
  if[k = count txt; :.aqc.lex.ok[`;txt;i + k]];
  at:i + k;
  if[at >= count src; :.aqc.lex.fail["end of input";at]];
  .aqc.lex.fail["`",(txt k),"' expected but ",(src at)," found";at]};


/ ---------------------------------------------------------------------------
/ Whitespace and comments   (Scala: StdLexical.whitespace)
/ ---------------------------------------------------------------------------

/ blockCommentEnd[src; i]
/   For a "/*" at offset i: the offset just after the first "*/".
/   Comments do not nest. If there is no "*/" before the end (or before a
/   0x1A byte), Scala does not see a comment at all: it returns i ("nothing
/   skipped") and the "/" and "*" are then lexed as delimiters.
/     blockCommentEnd["/* a */ b"; 0]   is 7
/     blockCommentEnd["/* a";      0]   is 0
.aqc.lex.blockCommentEnd:{[src;i]
  j:i + 2;
  while[not .aqc.lex.EOFCH = c:.aqc.lex.charAt[src;j];
    if[(c = "*") and "/" = .aqc.lex.charAt[src;j + 1]; :j + 2];
    j+:1];
  i};

/ skipOneWhitespace[src; i]
/   Skip one whitespace character or one comment at offset i. Whitespace is
/   any character up to " " except 0x1A. A // comment runs up to the next
/   newline or 0x1A (the newline is then skipped as whitespace).
/   returns: the offset after it, or i itself if there is none
.aqc.lex.skipOneWhitespace:{[src;i]
  c:.aqc.lex.charAt[src;i];
  if[(c <= " ") and c <> .aqc.lex.EOFCH; :i + 1];
  if[c <> "/"; :i];
  c2:.aqc.lex.charAt[src;i + 1];
  if[c2 = "/"; :.aqc.lex.skipUntil["\n";src;i + 2]];
  if[c2 = "*"; :.aqc.lex.blockCommentEnd[src;i]];
  i};

/ skipWhitespace[src; i]
/   Skip any mix of whitespace, // comments and /* */ comments.
/     skipWhitespace["  /* c */ x"; 0]   is 10
.aqc.lex.skipWhitespace:{[src;i]
  while[i < after:.aqc.lex.skipOneWhitespace[src;i]; i:after];
  i};


/ ---------------------------------------------------------------------------
/ The token rules, in the order Scala tries them (AqueryLexical.token)
/ Each rule[src; start] returns an ok or a fail result (see above).
/ ---------------------------------------------------------------------------

/ Rule 1: identifier or keyword.   Scala: identChar ~ rep(identChar | digit)
/ It is a Keyword if this exact spelling is reserved (see keywords.q).
/     "SELECT" -> Keyword;  "Select", "x_1" -> Identifier
.aqc.lex.identifier:{[src;start]
  if[not .aqc.lex.charAt[src;start] in .aqc.lex.identStart;
    :.aqc.lex.fail["identifier expected";start]];
  stop:.aqc.lex.skipWhile[.aqc.lex.identChars;src;start + 1];
  word:.aqc.lex.slice[src;start;stop];
  .aqc.lex.ok[$[.aqc.kw.isReserved word; `Keyword; `Identifier];word;stop]};

/ Rule 2: float.   Scala: rep1(digit) ~ '.' ~ rep(digit)
/     "3.14", "1."  (".5" is not a number: it is "." then "5")
.aqc.lex.float:{[src;start]
  dot:.aqc.lex.skipWhile[.Q.n;src;start];
  if[dot = start; :.aqc.lex.fail["digit expected";start]];
  r:.aqc.lex.expect[src;dot;"."];
  if[not r`ok; :r];
  stop:.aqc.lex.skipWhile[.Q.n;src;dot + 1];
  .aqc.lex.ok[`NumericLit;.aqc.lex.slice[src;start;stop];stop]};

/ Rule 3: integer.   Scala: digit ~ rep(digit)
/     "42", "007" (the zeros are kept)
.aqc.lex.int:{[src;start]
  stop:.aqc.lex.skipWhile[.Q.n;src;start];
  if[stop = start; :.aqc.lex.fail["digit expected";start]];
  .aqc.lex.ok[`NumericLit;.aqc.lex.slice[src;start;stop];stop]};

/ Rule 4: string.   Scala: '"' ~ rep(chrExcept('"', '\n', EofCh)) ~ '"'
/ No escape sequences; cannot contain a newline or 0x1A. The token text
/ leaves out the quotes.
/     "\"it's\""  -> StringLit it's
.aqc.lex.string:{[src;start]
  r:.aqc.lex.expect[src;start;"\""];
  if[not r`ok; :r];
  stop:.aqc.lex.skipUntil["\"\n";src;start + 1];
  r:.aqc.lex.expect[src;stop;"\""];
  if[not r`ok; :r];
  .aqc.lex.ok[`StringLit;.aqc.lex.slice[src;start + 1;stop];r`next]};

/ Dates and timestamps (rules 5 and 6). Scala reads a FIXED-WIDTH window
/ after the opening quote (10 characters for a date, 19 for a timestamp:
/ the length of "MM/dd/yyyy" and "MM/dd/yyyyDHH:mm:ss"), lets Java parse
/ the start of it, and then expects what follows right after the window,
/ however many characters the date really used. So '01/02/2020' is a date
/ but '1/2/2020' is an error: its closing quote is not where Scala looks.

/ window[src; start; width]
/   Up to width characters from offset start (fewer at the end of src).
.aqc.lex.window:{[src;start;width] .aqc.lex.slice[src;start;(count src) & start + width]};

/ Rule 5: timestamp.   Scala: '\'' ~> timestamp ~ (('.' ~> rep(digit)).? <~ '\'')
/ DIVERGES FROM SCALA on purpose (see README, "Intentional divergences"):
/   - the token is a Timestamp, not Scala's StringLit;
/   - no fraction of a second: the closing quote must follow the seconds,
/     as if Scala's ('.' ~> rep(digit)).? part were not there.
/     "'1/2/2020D1:2:3'"    -> Timestamp 01/02/2020D01:02:03
/     "'1/2/2020D1:2:3.5'"  -> fails at the "." ("`'' expected but . found")
.aqc.lex.timestamp:{[src;start]
  r:.aqc.lex.expect[src;start;"'"];
  if[not r`ok; :r];
  stampText:.aqc.jdate.normaliseTimestamp .aqc.lex.window[src;start + 1;19];
  if[0 = count stampText; :.aqc.lex.fail["Failed to parse datetime";start + 1]];
  r:.aqc.lex.expect[src;start + 1 + 19;"'"];
  if[not r`ok; :r];
  .aqc.lex.ok[`Timestamp;stampText;r`next]};

/ Rule 6: date.   Scala: '\'' ~> date <~ '\''
/     "'01/ 2/2020'" -> Date 01/02/2020
.aqc.lex.date:{[src;start]
  r:.aqc.lex.expect[src;start;"'"];
  if[not r`ok; :r];
  dateText:.aqc.jdate.normaliseDate .aqc.lex.window[src;start + 1;10];
  if[0 = count dateText; :.aqc.lex.fail["Failed to parse date";start + 1]];
  r:.aqc.lex.expect[src;start + 1 + 10;"'"];
  if[not r`ok; :r];
  .aqc.lex.ok[`Date;dateText;r`next]};

/ Rule 7: Scala: '"' ~> failure("unclosed string literal")
/ Always fails, just after the quote. It wins only when rule 4 also
/ failed right there (ties go to the later rule), e.g. for a lone ".
.aqc.lex.unclosedString:{[src;start]
  r:.aqc.lex.expect[src;start;"\""];
  if[not r`ok; :r];
  .aqc.lex.fail["unclosed string literal";start + 1]};

/ Rule 8: Scala: '\'' ~> failure("unclosed/invalid date/timestamp")
/ Always fails, just after the quote. For an invalid date this ties with
/ rules 5 and 6 and wins.
.aqc.lex.unclosedDate:{[src;start]
  r:.aqc.lex.expect[src;start;"'"];
  if[not r`ok; :r];
  .aqc.lex.fail["unclosed/invalid date/timestamp";start + 1]};

/ Rule 9: verbatim q code.   Scala: oVerbatim ~> rep(verbatimBodyChars) <~ cVerbatim
/ Scala reads the body in pieces (AqueryTokens.verbatimBodyChars):
/   any character but "<"                1 character
/   "<" + any character but "/"          2 characters
/   "</" + any character but "q"         3 characters
/   "</q" + any character but ">"        4 characters
/ and stops where none of these fits: at "</q>", or at the end.
/ Scala quirk: "<<" is one piece, so in "<q>a<</q>" the "</q>" starts
/ inside a piece and does not close the block.

/ verbatimPieceSize[src; i]
/   Size of the body piece at offset i, or 0 if none fits.
/     verbatimPieceSize["ab";   0]   is 1
/     verbatimPieceSize["</x";  0]   is 3
/     verbatimPieceSize["</q>"; 0]   is 0
.aqc.lex.verbatimPieceSize:{[src;i]
  matched:.aqc.lex.matchLength[src;i;"</q>"];
  size:$[matched = 4; 0; matched + 1];
  / a piece must fit inside the source
  $[(i + size) > count src; 0; size]};

/ verbatim[src; start]
/     "<q> x:1 </q>" -> Verbatim " x:1 "
.aqc.lex.verbatim:{[src;start]
  r:.aqc.lex.expect[src;start;"<q>"];
  if[not r`ok; :r];
  bodyStart:r`next;
  bodyStop:bodyStart;
  while[0 < size:.aqc.lex.verbatimPieceSize[src;bodyStop]; bodyStop+:size];
  r:.aqc.lex.expect[src;bodyStop;"</q>"];
  if[not r`ok; :r];
  .aqc.lex.ok[`Verbatim;.aqc.lex.slice[src;bodyStart;bodyStop];r`next]};

/ Rule 10: delimiter (operators and punctuation) -> Keyword token.
/ AqueryLexical.delimiters, in Scala's order. There is no lone "!".
.aqc.lex.delimiters:" " vs "@ * + - < = <> != <= >= > / ( ) == , ; % { } := : [ ] . & | ^ ~ <=>";

/ Scala tries the delimiters in reverse alphabetical order. That puts every
/ delimiter before its own prefixes ("<=>" before "<=" before "<"), so the
/ longest one wins.
.aqc.lex.delimiterOrder:desc .aqc.lex.delimiters;
.aqc.lex.delimiterFirst:first each .aqc.lex.delimiterOrder;   / their first characters

/ delimiter[src; start]
/   If none matches, the delimiter that got furthest gives the failure.
/     "<=x" -> Keyword <=
/     "!x"  -> fails at 1 with "`=' expected but x found" (from "!=")
.aqc.lex.delimiter:{[src;start]
  / Only delimiters with the right first character are tried. All others
  / fail right at start, and a failure at start never wins (rule 12 also
  / fails there, and is later), so skipping them changes nothing.
  candidates:.aqc.lex.delimiterOrder where .aqc.lex.delimiterFirst = .aqc.lex.charAt[src;start];
  furthest:.aqc.lex.fail["no matching delimiter";start];
  i:0;
  while[i < count candidates;
    r:.aqc.lex.expect[src;start;candidates i];
    if[r`ok; :.aqc.lex.ok[`Keyword;candidates i;r`next]];
    if[(r`at) >= furthest`at; furthest:r];
    i+:1];
  furthest};

/ Rule 11: Scala: EofCh ^^^ EOF
/ A real 0x1A byte in the source is an EOF token; lexing carries on after it.
/     "a\032b" -> Identifier a, EOF <eof>, Identifier b
.aqc.lex.eofChar:{[src;start]
  r:.aqc.lex.expect[src;start;.aqc.lex.EOFCH];
  if[not r`ok; :r];
  .aqc.lex.ok[`EOF;"<eof>";r`next]};

/ Rule 12: Scala: failure("illegal character"). Always fails, at start.
/     "#" -> ErrorToken *** error: illegal character
.aqc.lex.illegal:{[src;start] .aqc.lex.fail["illegal character";start]};

.aqc.lex.rules:(
  .aqc.lex.identifier;
  .aqc.lex.float;
  .aqc.lex.int;
  .aqc.lex.string;
  .aqc.lex.timestamp;
  .aqc.lex.date;
  .aqc.lex.unclosedString;
  .aqc.lex.unclosedDate;
  .aqc.lex.verbatim;
  .aqc.lex.delimiter;
  .aqc.lex.eofChar;
  .aqc.lex.illegal);


/ ---------------------------------------------------------------------------
/ The main loop
/ ---------------------------------------------------------------------------

/ nextToken[src; pos]
/   Try every rule at offset pos (pos < count src).
/   returns: the first ok result, or else the failure that got furthest
/            (on a tie, the later rule)
.aqc.lex.nextToken:{[src;pos]
  furthest:.aqc.lex.fail["";pos];
  i:0;
  while[i < count .aqc.lex.rules;
    r:.aqc.lex.rules[i][src;pos];
    if[r`ok; :r];
    if[(r`at) >= furthest`at; furthest:r];
    i+:1];
  furthest};

/ tokens[src]
/   PUBLIC. Lex AQuery source text.
/     tokens "SELECT a"   is
/       kind       text     line col
/       Keyword    "SELECT" 1    1
/       Identifier ,"a"     1    8
/       EOF        ""       1    9
/   src:     string (a one-character "x" works too)
/   returns: table with columns kind, text, line, col. The last row is
/            always EOF, at the position where the input ends.
.aqc.lex.tokens:{[src]
  src:(),src;                     / "x" is a char atom in q; make it a string
  n:count src;
  kinds:`symbol$(); texts:(); offsets:`long$();
  pos:.aqc.lex.skipWhitespace[src;0];
  while[pos < n;
    r:.aqc.lex.nextToken[src;pos];
    $[r`ok;
      [kinds,:r`kind; texts,:enlist r`text; offsets,:pos;
       pos:r`next];
      [kinds,:`ErrorToken; texts,:enlist "*** error: ",r`msg; offsets,:r`at;
       / Scala restarts one character after the error, unless that is
       / already the end of the input
       pos:$[(r`at) < n; 1 + r`at; r`at]]];
    pos:.aqc.lex.skipWhitespace[src;pos]];
  kinds,:`EOF; texts,:enlist ""; offsets,:pos;
  lineCol:.aqc.util.lineCol[src;offsets];
  ([] kind:kinds; text:texts; line:lineCol 0; col:lineCol 1)};


/ ---------------------------------------------------------------------------
/ Output in the golden-file format
/ ---------------------------------------------------------------------------

/ escapeText[txt]
/   Make token text printable on one line: backslash, tab, newline and
/   carriage return become \\ \t \n \r (as in tools/TokenDump.java).
/     escapeText "a\tb"   is "a\\tb"
.aqc.lex.escapeText:{[txt]
  txt:ssr[txt;"\\";"\\\\"];       / first, so the backslashes added below stay single
  txt:ssr[txt;"\t";"\\t"];
  txt:ssr[txt;"\n";"\\n"];
  ssr[txt;"\r";"\\r"]};

/ formatTokens[toks]
/   PUBLIC. One string per token: kind TAB text TAB line:col
/     formatTokens tokens "SELECT"   is ("Keyword\tSELECT\t1:1";"EOF\t\t1:7")
.aqc.lex.formatTokens:{[toks]
  / ,' joins two lists item by item (an atom is joined to every item)
  positions:(string toks`line),'":",'string toks`col;
  (string toks`kind),'"\t",'(.aqc.lex.escapeText each toks`text),'"\t",'positions};

/ lexFile[path]
/   PUBLIC. Lex a file (its raw bytes, as tools/TokenDump.java does) and
/   return its tokens formatted as golden-file lines.
/     lexFile "tests/inputs/financial/Q1.a"
.aqc.lex.lexFile:{[path] .aqc.lex.formatTokens .aqc.lex.tokens .aqc.util.readFile path};
