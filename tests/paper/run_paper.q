/ run_paper.q - run the AQueryKDB paper's examples one part at a time.

/ tests/paper/paper_queries.a holds every AQuery example from the paper,
/ cut into parts by comment lines that start with "// === ". This file reads
/ those parts and runs them with .aqc.run (src/runtime/run.q).
/ Load it after aquery.q, from the aquery-q folder:
/     bin/l_m64 aquery.q
/     \l tests/paper/run_paper.q
/     .paper.list[]        the parts: number, kind, title
/     .paper.run 4         run part 4: its setup part first, then part 4
/     .paper.runAll[]      run every query part, one row per part

/ A part's kind is the word after "// === ":
/     setup     makes tables. Before running a query, .paper.run runs the
/               nearest setup part above it, so every query starts with
/               fresh tables.
/     query     one query from the paper.
/     skipped   not run (the trigger example, for later).
/ A query part can have a line "// expect: <q code>". The q code is the
/ right answer. The result matches it when:
/     - the answer is a table and the result has the same columns in the
/       same order with the same values (column NAMES are not compared,
/       because the compiler picks its own names, like c__0), or
/     - the answer is a whole number and the result is a table with that
/       many rows, or
/     - the answer and the result are equal (~).


/ The file with the parts. .aqc.root is the aquery-q folder (set by aquery.q).
.paper.file:.aqc.root,"/tests/paper/paper_queries.a";

/ parseMarker[line]
/   The kind and title of a marker line.
/     parseMarker "// === query: Figure 3, HAVING ==="
/   is (`query; "Figure 3, HAVING").
.paper.parseMarker:{[line]
  inner:-4 _ 7 _ line;                  / drop "// === " and " ==="
  colon:inner?":";                      / position of the first ":"
  kind:`$colon#inner;                   / the word before it, as a symbol
  title:(colon+2) _ inner;              / the text after ": "
  (kind; title)};

/ expectOf[partLines]
/   The q code on the part's "// expect: " line, or "" when there is none.
.paper.expectOf:{[partLines]
  found:partLines where partLines like "// expect: *";
  $[0 = count found; ""; 11 _ first found]};   / 11 = length of "// expect: "

/ load[]
/   Read the file into the table .paper.parts, one row per part:
/   n (part number), kind, title, expect (q code or ""), text (AQuery).
.paper.load:{[]
  fileLines:read0 hsym `$.paper.file;
  starts:where fileLines like "// === *";
  chunks:starts cut fileLines;          / each chunk starts with its marker
  markers:.paper.parseMarker each first each chunks;
  .paper.parts:([]
    n:1 + til count chunks;
    kind:first each markers;
    title:last each markers;
    expect:.paper.expectOf each chunks;
    text:{[partLines] "\n" sv partLines} each chunks);
  count .paper.parts};

/ list[]
/   The parts, without their text.
/     .paper.list[]
.paper.list:{[] .paper.load[]; select n, kind, title from .paper.parts};

/ setupFor[k]
/   The number of the nearest setup part above part k (0 if there is none).
.paper.setupFor:{[k]
  above:exec n from .paper.parts where kind = `setup, n < k;
  $[0 = count above; 0; last above]};

/ runQuiet[k]
/   Run part k (its setup part first) and return its result. Prints nothing.
.paper.runQuiet:{[k]
  part:.paper.parts k - 1;              / row k-1 holds part k
  if[not part[`kind] in `setup`query; '"part ",(string k)," is ",string part`kind];
  s:.paper.setupFor k;
  if[(part[`kind] = `query) and s > 0; .aqc.run .paper.parts[s - 1; `text]];
  .aqc.run part`text};

/ run[k]
/   PUBLIC. Run part k, print its title and the q code it compiled to, and
/   return its result (the L prompt prints it).
/     .paper.run 9
.paper.run:{[k]
  .paper.load[];
  part:.paper.parts k - 1;
  -1 "part ",(string k),": ",part`title;
  result:.paper.runQuiet k;
  -1 "q code:\n",.aqc.lastCode;
  if[0 < count part`expect; -1 "expect: ",part`expect];
  result};

/ isTable[x]
/   1b if x is a table: type 98 (plain) or a keyed table (a dictionary,
/   type 99, whose key is a table).
.paper.isTable:{[x] $[98h = type x; 1b; 99h = type x; 98h = type key x; 0b]};

/ cells[x]
/   The values of a table's columns as a list (names left out), or x itself
/   when x is not a table. 0! turns a keyed table into a plain one.
.paper.cells:{[x] $[.paper.isTable x; value flip 0!x; x]};

/ matches[result; expectCode]
/   1b when result matches the answer in expectCode (rules at the top).
.paper.matches:{[result; expectCode]
  want:value expectCode;                / value runs q code given as text
  if[.paper.isTable[result] and -7h = type want; :want = count result];
  (.paper.cells result) ~ .paper.cells want};

/ check[k]
/   Run part k and describe how it went:
/   (status; rows; message), where status is
/     `ok       ran and matched its expect line
/     `wrong    ran but did not match
/     `ran      ran, no expect line to compare with
/     `error    failed; message is the error text
/     `skipped  a skipped part
.paper.check:{[k]
  part:.paper.parts k - 1;
  if[part[`kind] = `skipped; :(`skipped; 0N; "")];
  / @[f; x; handler] runs f x; if that signals an error, it returns
  / handler applied to the error text instead.
  outcome:@[{[j] (1b; .paper.runQuiet j)}; k; {[msg] (0b; msg)}];
  if[not first outcome; :(`error; 0N; last outcome)];
  result:last outcome;
  rows:$[.paper.isTable result; count result; 0N];
  if[0 = count part`expect; :(`ran; rows; "")];
  same:@[{[r; e] .paper.matches[r; e]}[result]; part`expect; {[msg] 0b}];
  $[same; (`ok; rows; ""); (`wrong; rows; "")]};

/ runAll[]
/   PUBLIC. Run every query and skipped part; one row per part with its
/   number, title, status, number of result rows and error message.
/     .paper.runAll[]
.paper.runAll:{[]
  .paper.load[];
  todo:select n, title from .paper.parts where kind <> `setup;
  outcomes:.paper.check each todo`n;
  update status:outcomes[;0], rows:outcomes[;1], message:outcomes[;2] from todo};
