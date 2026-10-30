# src/runtime — q support library used by generated code

- `base.q` is copied **unchanged** from
  `aquery-master/src/main/resources/q/base.q`. The Scala compiler prints it
  at the top of every compiled program, so `aquery.q -compile` prints it
  too (that keeps our output byte for byte equal to the jar's).
- `base_l.q` is the copy that L loads (version 5). It is `base.q` with one
  change: line 201 defines `.trg.kdbDeleteColsStmt:{[tbl;cols] ...}`, and L
  does not allow a built-in name (`cols`) as a parameter (`'type`, and the
  rest of the file is not loaded). In `base_l.q` the parameter is called
  `cs` (lines 201 and 202). `tests/runtime/test_run.q` checks that these
  are the only lines that differ. If `base.q` ever changes, remake the copy:

      sed -e '201s/{\[tbl;cols\]/{[tbl;cs]/' \
          -e '202s/\.trg\.symCode cols\]/.trg.symCode cs]/' \
          src/runtime/base.q > src/runtime/base_l.q

- `run.q` runs AQuery text in the running L process: `.aqc.run "SELECT ..."`
  and `.aqc.runFile "file.a"`. It runs the generated code one script
  statement at a time (see the top of the file for why).
- `console.q` adds `\aq` at the L prompt: it sets `.z.pi`, the function L
  calls with every typed line. `\aq` lines go to `.aqc.run`; other lines
  run as q and print the way L's own console prints them.
