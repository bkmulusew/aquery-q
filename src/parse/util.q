/ util.q - small helpers shared by the compiler stages.


/ readFile[path]
/   Read a whole file as a string, keeping every byte. (read0 would split
/   it into lines and lose the final newline.)
/   path:    string, e.g. "tests/inputs/financial/Q1.a"
/   returns: string
.aqc.util.readFile:{[path] "c"$read1 hsym `$path};


/ normalizeLines[text]
/   What the real Scala compiler does to a file before lexing it
/   (Aquery.scala: Source.fromFile(f).getLines().mkString("\n")):
/   "\r\n" and "\r" become "\n", and a final line break is dropped.
/     normalizeLines "a\r\nb\n"   is "a\nb"
/   The lexer and its golden tests do NOT use this: they lex the raw bytes,
/   exactly as tools/TokenDump.java does. The compiler's entry point will.
/   text:    string
/   returns: string
.aqc.util.normalizeLines:{[text]
  text:ssr[text;"\r\n";"\n"];
  text:ssr[text;"\r";"\n"];
  $["\n" ~ last text; -1 _ text; text]};


/ lineCol[text; offsets]
/   Turn 0-based character offsets into 1-based line and column numbers.
/   A "\n" belongs to the line it ends. Offsets past the end of text are
/   allowed (they count as being on the last line).
/     lineCol["ab\ncd"; 0 3 4]   is (1 2 2; 1 1 2)
/   text:    string
/   offsets: list of longs
/   returns: (lines; columns), two lists of longs
.aqc.util.lineCol:{[text;offsets]
  newlines:where text = "\n";
  / newlines bin o-1 is the index of the last newline before offset o
  / (-1 if there is none), so this counts the newlines before each offset
  before:1 + newlines bin offsets - 1;
  / the offset where each of those lines starts: 0 for line 1, else just
  / after the newline that ends the previous line
  lineStart:(0,1 + newlines) before;
  (1 + before; 1 + offsets - lineStart)};
