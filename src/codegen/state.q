/ state.q - what the code generator remembers while it writes q code.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/codegen/:
/ KdbGenerator.scala (case class CodeState and the small functions that
/ read and change it) and SimpleState.scala.

/ HOW STATE WORKS HERE
/ Scala passes a CodeState record through every generator function with a
/ State monad: each function gets the current state and hands back a new
/ one together with its q code. q has no monads, so the state is one
/ global dictionary, .aqc.gen.st, read with .aqc.gen.get and changed with
/ .aqc.gen.set. A Scala "for" block such as
/     for (temp <- genTempTableName(); _ <- setCurrTable(temp)) yield ...
/ becomes plain statements, run top to bottom:
/     temp:.aqc.gen.newTableName[];
/     .aqc.gen.set[`currTable; temp];
/ A Q TRAP: inside one q expression the right-hand side runs first, so
/ (.aqc.gen.plan a),.aqc.gen.plan b generates b before a. Whenever a step
/ changes the state, give it its own statement and a local variable.
/ .aqc.gen.generate (gen.q) starts every program from a fresh state, so the
/ global dictionary never leaks from one program into the next.


/ fresh[]
/   A new state, as Scala's CodeState() with its default values:
/     queryId     next query number, for the .aq.qN function names
/     tableId     next temporary table number, for the aq__tN names
/     currTable   name of the table the current step reads (a string)
/     grouped     1b once a GROUP BY was generated: function calls then
/                 get q's each, f'
/     nameAsVar   1b: a name is a q variable, not a column lookup
/     inUDF       1b: inside a FUNCTION body
/     renameCols  1b: tables get their columns renamed table.col (joins)
.aqc.gen.fresh:{[]
  `queryId`tableId`currTable`grouped`nameAsVar`inUDF`renameCols!(0;0;"";0b;0b;0b;0b)};

/ The state itself.
.aqc.gen.st:.aqc.gen.fresh[];

/ get[field]
/   The value of one field of the state.
/     .aqc.gen.get `grouped   is 0b   (in a fresh state)
.aqc.gen.get:{[field] .aqc.gen.st field};

/ set[field; v]
/   Change one field of the state. (A dotted name such as .aqc.gen.st is
/   global, so assigning to it inside a function changes the global.)
/     .aqc.gen.set[`grouped; 1b]
.aqc.gen.set:{[field;v] .aqc.gen.st[field]:v;};

/ newTableName[]
/   A fresh temporary table name, "aq__t0", "aq__t1", ... (Scala:
/   genTempTableName). Uses tableId and adds 1 to it.
.aqc.gen.newTableName:{[]
  id:.aqc.gen.get `tableId;
  .aqc.gen.set[`tableId; id + 1];
  "aq__t",string id};

/ cleanTopEnv[]
/   Reset the state before each top-level statement, keeping only the
/   query number (Scala: cleanTopEnv).
.aqc.gen.cleanTopEnv:{[]
  q:.aqc.gen.get `queryId;
  .aqc.gen.st:.aqc.gen.fresh[];
  .aqc.gen.set[`queryId; q];};

/ cleanQueryEnv[]
/   Reset the state before each query, keeping the query number and the
/   temporary table number, so WITH queries and the main query never use
/   the same aq__tN name (Scala: cleanQueryEnv).
.aqc.gen.cleanQueryEnv:{[]
  q:.aqc.gen.get `queryId;
  t:.aqc.gen.get `tableId;
  .aqc.gen.st:.aqc.gen.fresh[];
  .aqc.gen.set[`queryId; q];
  .aqc.gen.set[`tableId; t];};


/ ---------------------------------------------------------------------------
/ Text helpers
/ ---------------------------------------------------------------------------

/ str[x]
/   x as a string: a one-character string may be stored as a char atom
/   (see src/parse/ast.q). The same as .aqc.dot.str.
.aqc.gen.str:.aqc.dot.str;

/ join[sep; strs]
/   The strings strs with sep between them (Scala: strs.mkString(sep)).
/   The same as .aqc.dot.join (a loop, because sv fails in L when sep is
/   one character).
/     join[";"; ("a";"b")]   is "a;b"
.aqc.gen.join:.aqc.dot.join;

/ sym[s]
/   A q symbol literal for the name s (Scala: kdbSym).
/     sym "price"   is "`price"
.aqc.gen.sym:{[s] "`",.aqc.gen.str s};

/ bool[b]
/   A q boolean literal (Scala: kdbBool).
/     bool 1b   is "1b"
.aqc.gen.bool:{[b] $[b; "1b"; "0b"]};
