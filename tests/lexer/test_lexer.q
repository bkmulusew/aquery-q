/ test_lexer.q - hand-written unit tests for the lexer, one group per
/ token kind. Each test lexes a short string and checks the result.

/ Run from the aquery-q folder:   bin/l_m64 tests/lexer/test_lexer.q

/ The expected values were checked against the Scala lexer (the golden
/ files cover the same cases on whole files; these tests pin down each rule
/ on its own so a failure points straight at the broken rule).


.aqc.root:".";
\l aquery.q
\l tests/lib/testing.q


/ brief[src]
/   Lex src and describe each token as "Kind text", leaving out the final
/   EOF token and the positions. Makes the expected values short.
/   returns: list of strings
brief:{[src]
  toks:.aqc.lex.tokens src;
  toks:-1 _ toks;
  result:();
  i:0;
  while[i < count toks;
    row:toks i;
    result,:enlist (string row`kind)," ",.aqc.lex.escapeText row`text;
    i+:1];
  result};

/ positions[src]
/   Lex src and give each token's position as "line:col", including EOF.
positions:{[src]
  toks:.aqc.lex.tokens src;
  {(string x`line),":",string x`col} each toks};


/ ---------------------------------------------------------------------------
/ Whitespace, comments and EOF
/ ---------------------------------------------------------------------------

.test.check["empty input is just EOF"; .aqc.lex.formatTokens .aqc.lex.tokens ""; enlist "EOF\t\t1:1"];
.test.check["whitespace only: EOF after it"; positions "  \n\t\n "; enlist "3:2"];
.test.check["spaces and tabs separate tokens"; brief "a \t b"; ("Identifier a";"Identifier b")];
.test.check["control characters count as whitespace"; brief "a\001b"; ("Identifier a";"Identifier b")];
.test.check["line comment is skipped"; brief "a // note\nb"; ("Identifier a";"Identifier b")];
.test.check["line comment at end of input"; positions "a // end"; ("1:1";"1:9")];
.test.check["block comment is skipped"; brief "a /* x\ny */ b"; ("Identifier a";"Identifier b")];
.test.check["empty block comment"; brief "a/**/b"; ("Identifier a";"Identifier b")];
.test.check["/*/ does not close a comment"; brief "a /*/ x */ b"; ("Identifier a";"Identifier b")];
.test.check["unclosed block comment is lexed as tokens"; brief "a /* b"; ("Identifier a";"Keyword /";"Keyword *";"Identifier b")];
.test.check["single slash is division"; brief "a/b"; ("Identifier a";"Keyword /";"Identifier b")];
.test.check["character 26 mid-text is an EOF token, lexing goes on"; brief "a\032b"; ("Identifier a";"EOF <eof>";"Identifier b")];
.test.check["character 26 ends a line comment"; brief "a // x\032b"; ("Identifier a";"EOF <eof>";"Identifier b")];
.test.check["character 26 leaves a block comment unclosed"; brief "/* \032 */"; ("Keyword /";"Keyword *";"EOF <eof>";"Keyword *";"Keyword /")];
.test.check["character 26 is allowed in a verbatim body"; brief "<q>\032</q>"; enlist "Verbatim \032"];


/ ---------------------------------------------------------------------------
/ Identifiers and keywords
/ ---------------------------------------------------------------------------

.test.check["identifiers"; brief "x _y a_b2 A1"; ("Identifier x";"Identifier _y";"Identifier a_b2";"Identifier A1")];
.test.check["keyword in upper case"; brief "SELECT"; enlist "Keyword SELECT"];
.test.check["keyword in lower case"; brief "select"; enlist "Keyword select"];
.test.check["mixed case is an identifier"; brief "Select sElEcT"; ("Identifier Select";"Identifier sElEcT")];
.test.check["INT is a keyword but int is not"; brief "INT int"; ("Keyword INT";"Identifier int")];
.test.check["all upper-case-only type names"; brief "date DATE timestamp TIMESTAMP"; ("Identifier date";"Keyword DATE";"Identifier timestamp";"Keyword TIMESTAMP")];
.test.check["keyword followed by digits is an identifier"; brief "SELECT1"; enlist "Identifier SELECT1"];
.test.check["dotted names are three tokens"; brief "t.c1"; ("Identifier t";"Keyword .";"Identifier c1")];
.test.check["198 keyword spellings"; count .aqc.kw.reserved; 198];
.test.check["32 keywords are functions"; sum .aqc.kw.table`isFunction; 32];
.test.check["COUNT is a function, SELECT is not"; exec isFunction from .aqc.kw.table where word in `COUNT`SELECT; 10b];


/ ---------------------------------------------------------------------------
/ Numbers
/ ---------------------------------------------------------------------------

.test.check["integer"; brief "42"; enlist "NumericLit 42"];
.test.check["leading zeros are kept"; brief "007"; enlist "NumericLit 007"];
.test.check["float"; brief "3.14"; enlist "NumericLit 3.14"];
.test.check["float with no digits after the dot"; brief "1."; enlist "NumericLit 1."];
.test.check[".5 is a dot then an integer"; brief ".5"; ("Keyword .";"NumericLit 5")];
.test.check["1.2.3 is a float, a dot, an integer"; brief "1.2.3"; ("NumericLit 1.2";"Keyword .";"NumericLit 3")];
.test.check["number then identifier"; brief "1abc"; ("NumericLit 1";"Identifier abc")];
.test.check["minus is a separate token"; brief "-1"; ("Keyword -";"NumericLit 1")];


/ ---------------------------------------------------------------------------
/ Strings
/ ---------------------------------------------------------------------------

.test.check["string text excludes the quotes"; brief "\"hello world\""; enlist "StringLit hello world"];
.test.check["empty string"; brief "\"\""; enlist "StringLit "];
.test.check["backslash is an ordinary character"; brief "\"a\\b\""; enlist "StringLit a\\\\b"];
.test.check["single quote inside a string"; brief "\"it's\""; enlist "StringLit it's"];
.test.check["unclosed string: error at the newline"; .aqc.lex.formatTokens .aqc.lex.tokens "x \"ab\ny";
  ("Identifier\tx\t1:1";"ErrorToken\t*** error: `\"' expected but \\n found\t1:6";"Identifier\ty\t2:1";"EOF\t\t2:2")];
.test.check["unclosed string at end of input"; brief "\"ab"; enlist "ErrorToken *** error: end of input"];
.test.check["lone quote at end of input"; brief "\""; enlist "ErrorToken *** error: unclosed string literal"];


/ ---------------------------------------------------------------------------
/ Delimiters
/ ---------------------------------------------------------------------------

.test.check["30 delimiters"; count .aqc.lex.delimiters; 30];
.test.check["longest delimiter wins"; brief "a<=>b"; ("Identifier a";"Keyword <=>";"Identifier b")];
.test.check["two-character delimiters"; brief "<> != <= >= == :="; ("Keyword <>";"Keyword !=";"Keyword <=";"Keyword >=";"Keyword ==";"Keyword :=")];
.test.check["::  is two colons"; brief "::"; ("Keyword :";"Keyword :")];
.test.check["single-character delimiters"; brief "@*+-<=>/(),;%{}:[].&|^~";
  ("Keyword @";"Keyword *";"Keyword +";"Keyword -";"Keyword <=>";"Keyword /";"Keyword (";"Keyword )";
   "Keyword ,";"Keyword ;";"Keyword %";"Keyword {";"Keyword }";"Keyword :";"Keyword [";"Keyword ]";
   "Keyword .";"Keyword &";"Keyword |";"Keyword ^";"Keyword ~")];
.test.check["! alone is an error and swallows the next character"; brief "!x y"; ("ErrorToken *** error: `=' expected but x found";"Identifier y")];
.test.check["! error is reported one character in"; positions "!x"; ("1:2";"1:3")];


/ ---------------------------------------------------------------------------
/ Dates and timestamps
/ ---------------------------------------------------------------------------

.test.check["date"; brief "'01/02/2020'"; enlist "Date 01/02/2020"];
.test.check["leap day in a leap year"; brief "'02/29/2020'"; enlist "Date 02/29/2020"];
.test.check["Julian leap year before 1582"; brief "'02/29/1500'"; enlist "Date 02/29/1500"];
.test.check["short fields are padded"; brief "'1/02/20201'"; enlist "Date 01/02/20201"];
.test.check["timestamp is a StringLit"; brief "'01/02/2020D10:11:12'"; enlist "StringLit 01/02/2020D10:11:12"];
.test.check["timestamp fraction is copied"; brief "'01/02/2020D10:11:12.123'"; enlist "StringLit 01/02/2020D10:11:12.123"];
.test.check["timestamp with a bare dot"; brief "'01/02/2020D10:11:12.'"; enlist "StringLit 01/02/2020D10:11:12."];
.test.check["invalid date: error, then the pieces are lexed";
  brief "'13/45/2020'";
  ("ErrorToken *** error: unclosed/invalid date/timestamp";"NumericLit 3";"Keyword /";"NumericLit 45";
   "Keyword /";"NumericLit 2020";"ErrorToken *** error: unclosed/invalid date/timestamp")];
.test.check["02/29/2021 is not a date"; first brief "'02/29/2021'"; "ErrorToken *** error: unclosed/invalid date/timestamp"];
.test.check["hour 24 is not a timestamp (the date part then fails on D)";
  first brief "'01/02/2020D24:00:00'"; "ErrorToken *** error: `'' expected but D found"];
.test.check["unclosed date at end of input"; brief "'01/02/2020"; enlist "ErrorToken *** error: end of input"];
.test.check["lone single quote"; brief "'"; enlist "ErrorToken *** error: unclosed/invalid date/timestamp"];
.test.check["date positions can run past the end of input"; positions "'1/2/3'"; ("1:12";"1:12")];

/ The date helpers on their own
.test.check["normaliseDate valid"; .aqc.jdate.normaliseDate "12/31/9999"; "12/31/9999"];
.test.check["normaliseDate ignores trailing text"; .aqc.jdate.normaliseDate "1/2/3'xyz"; "01/02/0003"];
.test.check["normaliseDate rejects year 0"; .aqc.jdate.normaliseDate "01/01/0000"; ""];
.test.check["normaliseDate rejects the 1582 gap"; .aqc.jdate.normaliseDate "10/10/1582"; ""];
.test.check["normaliseDate rejects 1900-02-29"; .aqc.jdate.normaliseDate "02/29/1900"; ""];
.test.check["normaliseDate skips spaces before a number"; .aqc.jdate.normaliseDate " 1/ 2/2020"; "01/02/2020"];
.test.check["normaliseDate rejects a missing field"; .aqc.jdate.normaliseDate "01//2020"; ""];
.test.check["exponent in a date field: 1E3 is year 1000"; .aqc.jdate.normaliseDate "1/2/1E3"; "01/02/1000"];
.test.check["exponent too big wraps to a negative year"; .aqc.jdate.normaliseDate "01/02/2E10"; ""];
.test.check["E without digits is not an exponent"; .aqc.jdate.normaliseDate "1/2/2E"; "01/02/0002"];
.test.check["javaInt keeps normal numbers"; .aqc.jdate.javaInt 2020; 2020];
.test.check["javaInt wraps like Java's intValue"; .aqc.jdate.javaInt 20000000000; -1474836480];
.test.check["normaliseTimestamp valid"; .aqc.jdate.normaliseTimestamp "1/2/2020D1:2:3"; "01/02/2020D01:02:03"];
.test.check["normaliseTimestamp rejects second 60"; .aqc.jdate.normaliseTimestamp "01/02/2020D10:11:60"; ""];
.test.check["normaliseTimestamp needs a capital D"; .aqc.jdate.normaliseTimestamp "01/02/2020d10:11:12"; ""];


/ ---------------------------------------------------------------------------
/ Verbatim q code
/ ---------------------------------------------------------------------------

.test.check["verbatim block"; brief "<q> x:1 </q>"; enlist "Verbatim  x:1 "];
.test.check["empty verbatim block"; brief "<q></q>"; enlist "Verbatim "];
.test.check["verbatim keeps newlines"; brief "<q>\na\n</q>"; enlist "Verbatim \\na\\n"];
.test.check["< and </x inside verbatim"; brief "<q>1<2;\"</x>\"</q>"; enlist "Verbatim 1<2;\"</x>\""];
.test.check["</q followed by something else does not close"; brief "<q> </q </q>"; enlist "Verbatim  </q "];
.test.check["<< swallows the next character (Scala quirk)"; brief "<q> a<<b </q>"; enlist "Verbatim  a<<b "];
.test.check["<</q> does not close the block (Scala quirk)"; brief "<q>a<</q>";
  ("Keyword <";"Identifier q";"Keyword >";"Identifier a";"Keyword <";"Keyword <";"Keyword /";"Identifier q";"Keyword >")];
.test.check["unclosed verbatim is lexed as tokens"; brief "<q> x";
  ("Keyword <";"Identifier q";"Keyword >";"Identifier x")];


/ ---------------------------------------------------------------------------
/ Errors and positions
/ ---------------------------------------------------------------------------

.test.check["illegal character"; brief "a # b"; ("Identifier a";"ErrorToken *** error: illegal character";"Identifier b")];
.test.check["other illegal characters"; brief "$?"; ("ErrorToken *** error: illegal character";"ErrorToken *** error: illegal character")];
.test.check["lexing continues after an error"; positions "# a"; ("1:1";"1:3";"1:4")];
.test.check["line and column numbers"; positions "a\n  bc\n\nd"; ("1:1";"2:3";"4:1";"4:2")];
.test.check["tab counts as one column"; positions "\tx"; ("1:2";"1:3")];
.test.check["formatted line: kind TAB text TAB line:col"; first .aqc.lex.formatTokens .aqc.lex.tokens "  SELECT"; "Keyword\tSELECT\t1:3"];
.test.check["escapeText"; .aqc.lex.escapeText "a\tb\nc\\d\re"; "a\\tb\\nc\\\\d\\re"];


/ ---------------------------------------------------------------------------
/ Helpers (util.q and the small lexer helpers)
/ ---------------------------------------------------------------------------

.test.check["one-character source"; brief "x"; enlist "Identifier x"];
.test.check["lineCol"; .aqc.util.lineCol["ab\ncd";0 2 3 4 9]; (1 1 2 2 2;1 3 1 2 7)];
.test.check["normalizeLines: CRLF and CR become LF"; .aqc.util.normalizeLines "a\r\nb\rc"; "a\nb\nc"];
.test.check["normalizeLines drops one final newline"; .aqc.util.normalizeLines "a\n\n"; "a\n"];
.test.check["normalizeLines of empty text"; .aqc.util.normalizeLines ""; ""];
.test.check["matchLength stops at the first mismatch"; .aqc.lex.matchLength["<=x";0;"<=>"]; 2];
.test.check["matchLength never counts past the end"; .aqc.lex.matchLength["a<";1;"<=>"]; 1];
.test.check["expect: wrong character"; .aqc.lex.expect["<=x";0;"<=>"]; `ok`msg`at!(0b;"`>' expected but x found";2)];
.test.check["expect: end of input"; .aqc.lex.expect["<=";0;"<=>"]; `ok`msg`at!(0b;"end of input";2)];
.test.check["blockCommentEnd"; .aqc.lex.blockCommentEnd["/* a */ b";0]; 7];
.test.check["blockCommentEnd unclosed"; .aqc.lex.blockCommentEnd["/* a";0]; 0];
.test.check["verbatimPieceSize"; .aqc.lex.verbatimPieceSize["</x";0],.aqc.lex.verbatimPieceSize["</q>";0],.aqc.lex.verbatimPieceSize[enlist "<";0]; 3 0 0];
.test.check["keyword table is alphabetical"; .aqc.kw.table`word; asc .aqc.kw.table`word];
.test.check["isReserved"; .aqc.kw.isReserved each ("select";"Select";"int";"INT"); 1001b];

.test.finish[];
