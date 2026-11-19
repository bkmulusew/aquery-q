/ errors.q - the errors the type checker reports (version 6).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/analysis/errors.scala.

/ An error is a dictionary with 4 keys:
/   kind   which error, Scala's class name: `TypeError, `BadCall,
/          `DuplicateTableName, `UnknownCorrName, `AmbigColAccess or
/          `IllegalExpr
/   args   what the message needs, a list (see each maker below)
/   pos    where the error is: (line; column), or an empty list for a node
/          with no position (Scala prints [0,0] then)
/   pos2   a second position (only DuplicateTableName uses it)
/ All errors have the same keys, so q turns a list of errors into a table,
/ one row per error. Lists of errors are built with .aqc.ast.append and
/ .aqc.ast.concat, which work on both (see "A Q TRAP" in src/parse/ast.q).
/ Scala also defines NumArgsError, but nothing creates one, so it is left out.


/ ---------------------------------------------------------------------------
/ Making errors
/ ---------------------------------------------------------------------------

/ make[kind; args; pos]
/   An error with no second position.
.aqc.tc.err.make:{[kind;args;pos] `kind`args`pos`pos2!(kind; args; pos; `long$())};

/ typeError[expected; found; pos]
/   A value of type found where type expected was needed.
/     typeError[`numeric; `string; 1 9]
/   prints as
/     Type Error: expected numeric found string at [1,9]
.aqc.tc.err.typeError:{[expected;found;pos] .aqc.tc.err.make[`TypeError; (expected; found); pos]};

/ badCall[f; pos]
/   A call to function f (a string) whose arguments do not fit.
/     Call Error: bad call to SQRT at [4,17]
.aqc.tc.err.badCall:{[f;pos] .aqc.tc.err.make[`BadCall; enlist f; pos]};

/ duplicateTable[t1; t2; pos; pos2]
/   The same table (or correlation name) twice in one FROM. t1 and t2 are
/   strings: "t", or "t as a" when the table has a correlation name.
/     Table Error: Duplicate table t at [1,15] and t at [1,18]
.aqc.tc.err.duplicateTable:{[t1;t2;pos;pos2]
  e:.aqc.tc.err.make[`DuplicateTableName; (t1; t2); pos];
  e[`pos2]:pos2;
  e};

/ unknownCorrName[ca; pos]
/   t.c where t is not a table of the query. ca is the text "t.c".
/     Table Error: Unknown correlation name in q.a at [2,8]
.aqc.tc.err.unknownCorrName:{[ca;pos] .aqc.tc.err.make[`UnknownCorrName; enlist ca; pos]};

/ ambigColAccess[ca; pos]
/   t.c where two tables of the query are both called t.
/     Table Error: Ambiguous column access in t.c at [1,8]
.aqc.tc.err.ambigColAccess:{[ca;pos] .aqc.tc.err.make[`AmbigColAccess; enlist ca; pos]};

/ illegalExpr[s; pos]
/   An expression that is not allowed here. s is its text as the -p graph
/   prints it (.aqc.dot.label), e.g. "b+1".
/     Expr Error: Illegal expression in b+1 at [2,39]
.aqc.tc.err.illegalExpr:{[s;pos] .aqc.tc.err.make[`IllegalExpr; enlist s; pos]};


/ ---------------------------------------------------------------------------
/ Printing errors
/ ---------------------------------------------------------------------------

/ str[x]
/   x as a string. A one-character string can be a char atom in q
/   ("f" alone); enlist turns it into a real string.
.aqc.tc.err.str:{[x] $[-10h = type x; enlist x; x]};

/ loc[pos]
/   A position as Scala prints it: "[1,9]", or "[0,0]" for no position.
.aqc.tc.err.loc:{[pos]
  if[0 = count pos; :"[0,0]"];
  "[",(string pos 0),",",(string pos 1),"]"};

/ message[e]
/   The line Scala prints for error e (Scala: each error's toString).
.aqc.tc.err.message:{[e]
  a:e`args;
  at:" at ",.aqc.tc.err.loc e`pos;
  k:e`kind;
  if[k = `TypeError;
    :"Type Error: expected ",(string a 0)," found ",(string a 1),at];
  if[k = `BadCall;
    :"Call Error: bad call to ",(.aqc.tc.err.str a 0),at];
  if[k = `DuplicateTableName;
    :"Table Error: Duplicate table ",(.aqc.tc.err.str a 0),at,
      " and ",(.aqc.tc.err.str a 1)," at ",.aqc.tc.err.loc e`pos2];
  if[k = `UnknownCorrName;
    :"Table Error: Unknown correlation name in ",(.aqc.tc.err.str a 0),at];
  if[k = `AmbigColAccess;
    :"Table Error: Ambiguous column access in ",(.aqc.tc.err.str a 0),at];
  if[k = `IllegalExpr;
    :"Expr Error: Illegal expression in ",(.aqc.tc.err.str a 0),at];
  '"message: unknown error kind ",string k};
