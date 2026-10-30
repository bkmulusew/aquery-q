/ console.q - the \aq command at the L prompt.

/ After loading aquery.q you can type AQuery at the L prompt:
/     l>t:([] a:1 2 3; b:10 20 30)
/     l>\aq SELECT a, b FROM t WHERE a > 1
/     a b
/     ----
/     2 20
/     3 30
/ Every other line is ordinary q and behaves as before.

/ HOW IT WORKS
/ L sends every line you type at the prompt to the function .z.pi, if one
/ is defined ("pi" for "prompt input"), instead of running the line
/ itself. L has no way to add new backslash commands (it hands unknown
/ ones such as \aq to the shell), so the \aq line is caught here:
/ a line starting with \aq is AQuery, anything else is q.
/ Because .z.pi replaces L's own handling of q lines too, .aqc.console.q
/ copies what L's console does (checked by tests/runtime/test_console.sh):
/   - it prints the result, except when the result is :: (nothing) or the
/     line is an assignment (a:5, a+:1)
/   - an error prints as 'TIME message and the session goes on
/ The prompt itself ("l>") is still printed by L.


/ print[x]
/   Print a value the way the console does: nothing for ::, otherwise the
/   text of .Q.s (q's own console format, ending with a line break).
.aqc.console.print:{[x]
  if[not (::) ~ x; 1 .Q.s x];
  };

/ error[msg]
/   Print an error the way L's console does: 'TIME msg (local time).
/     error "type"   prints   '2026.10.29T10:56:44.333 type
.aqc.console.error:{[msg] -1 "'",(string .z.Z)," ",msg;};

/ isAssignment[line]
/   1b if the q line assigns a variable (a:5, a+:1, a[0]:1); L's console
/   prints nothing for those. parse turns the line into a parse tree:
/     a:5      is (:;`a;5)      operator ":", then the name and the value
/     a+:1     is (+:;`a;1)     operator "+:"
/     count s  is (#:;`s)       also ends with ":" (the one-argument form
/                               of #), but has no value, so 2 items
/     g[1;2]   is (`g;1;2)      3 items, but the first is a name, not
/                               an operator
/   So an assignment is 3 items whose operator is ":" or ends with ":".
/   A line that does not parse is not an assignment (running it will then
/   show the error).
/     isAssignment "a:5"     is 1b
/     isAssignment "b:1;2"   is 0b   (the line's value is 2, which L prints)
.aqc.console.isAssignment:{[line]
  tree:@[parse; line; {[msg] ::}];
  if[not 0h = type tree; :0b];            / an atom such as `a: no operator
  if[not 3 = count tree; :0b];
  / an operator has a function type (100h to 112h); -3! (the text of a
  / value) fails in L on some atoms, so it is only used on these
  if[not (type first tree) within 100 112h; :0b];
  op:-3!first tree;                        / the operator as text
  (":" = last op) and 2 >= count op};

/ q[line]
/   Run one q line as L's console would.
.aqc.console.q:{[line]
  if[all line in " \t"; :(::)];            / an empty line does nothing
  / outcome is (1b; the line's value), or (0b; the error message)
  outcome:@[{[l] (1b; value l)}; line; {[msg] (0b; msg)}];
  $[not first outcome; .aqc.console.error outcome 1;
    .aqc.console.isAssignment line; ::;
    .aqc.console.print outcome 1];
  };

/ aq[text]
/   Run the AQuery text after "\aq" and print its result. A parse error
/   prints as 'aq: parse error at line:col: message; a q error while running
/   the query prints as 'message, with a hint to look at the q code.
.aqc.console.aq:{[text]
  / outcome is (1b; the result), or (0b; the error message)
  outcome:@[{[t] (1b; .aqc.run t)}; text; {[msg] (0b; msg)}];
  if[first outcome; :.aqc.console.print outcome 1];
  msg:outcome 1;
  $["parse error" ~ 11 # msg;
    -1 "'aq: ",msg;
    [-1 "'",msg;
     -1 "  (the q code of this query: -1 .aqc.lastCode)"]];
  };

/ isAq[line]
/   1b if the line is an \aq command: "\aq" alone, or "\aq " and text.
.aqc.console.isAq:{[line] (line ~ "\\aq") or line like "\\aq[ \t]*"};

/ handle[line]
/   PUBLIC. What happens to each line typed at the prompt.
/   For \aq, 4 _ drops "\aq" and the blank after it, so that a parse error
/   at 1:8 means the 8th character of the query itself.
.aqc.console.handle:{[line]
  line:(),line;                      / a one-character line as a string
  $[.aqc.console.isAq line;
    .aqc.console.aq 4 _ line;
    .aqc.console.q line];
  };

.z.pi:{[line] .aqc.console.handle line};
