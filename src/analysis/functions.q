/ functions.q - what the type checker knows about functions (version 6).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/analysis/
/ FunctionInfo.scala and functionSummaries.scala.

/ For each function the checker keeps a row with:
/   name                 the function's name as a symbol: built-ins in upper
/                        case (the parser upper-cases them), UDFs as written
/   sigs                 its signature: the names of one or more functions in
/                        .aqc.fn.sig, tried in order (see below)
/   orderDependent       does the result depend on the order of the rows?
/                        (SUMS yes, SUM no)
/   remOrderDependence   is the result free of row order again? (SUM, MAX:
/                        one value for the whole column)
/   usesAggregate        does it combine several rows?
/   nargs                for a UDF, how many arguments it takes; 0N (null)
/                        for a built-in
/ The three order flags are not used by the type checker. The order
/ analysis (version 7) reads them from this same table.


/ ---------------------------------------------------------------------------
/ Signatures
/ ---------------------------------------------------------------------------

/ A signature says which argument types a function accepts and what type it
/ returns. Each one is a function of ts, the list of argument types (a
/ symbol list, one tag per argument). It returns the result type, or `bad
/ when the call does not fit. (Scala uses "partial functions" for this: a
/ lambda that only answers for some inputs. `bad stands for "no answer".)
/ The names follow Scala's: numToNum is Scala's num_Num, and so on.
/ Some built-ins have two signatures, which Scala joins with "orElse": the
/ second is tried when the first says `bad. The sigs column lists them in
/ that order.

/ One numeric argument; returns `numeric.  ABS, SQRT, SUM, DELTAS
/   numToNum[enlist `numeric]   is `numeric
/   numToNum[enlist `string]    is `bad
/   numToNum[`numeric`numeric]  is `bad   (wrong number of arguments)
.aqc.fn.sig.numToNum:{[ts]
  $[1 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.num]; `numeric;
    `bad]};

/ One boolean argument; returns `boolean.  NOT
.aqc.fn.sig.boolToBool:{[ts]
  $[1 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.bool]; `boolean;
    `bad]};

/ One boolean argument; returns `numeric.  SUM (its second signature)
.aqc.fn.sig.boolToNum:{[ts]
  $[1 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.bool]; `numeric;
    `bad]};

/ One argument of any type; returns that same type.  FIRST, LAST, NEXT, PREV, FILLS
/   selfToSelf[enlist `string]   is `string
.aqc.fn.sig.selfToSelf:{[ts] $[1 <> count ts; `bad; ts 0]};

/ One numeric or boolean argument; returns that same type.  MAXS, MINS
.aqc.fn.sig.boolOrNumToSelf:{[ts]
  $[1 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.numAndBool]; ts 0;
    `bad]};

/ One numeric or boolean argument; returns `numeric.  AVG, PRD, AVGS, SUMS, ...
.aqc.fn.sig.boolOrNumToNum:{[ts]
  $[1 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.numAndBool]; `numeric;
    `bad]};

/ Two arguments, the first numeric; returns the type of the second.
/ DROP, and FIRST(n, x), LAST(n, x), ...
/   numAndSelfToSelf[`numeric`string]   is `string
.aqc.fn.sig.numAndSelfToSelf:{[ts]
  $[2 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.num]; ts 1;
    `bad]};

/ Two arguments of the same type; returns that type.  FILL, FILLS(x, y)
/   selfAndSelfToSelf[`numeric`numeric]   is `numeric
/   selfAndSelfToSelf[`numeric`string]    is `bad
.aqc.fn.sig.selfAndSelfToSelf:{[ts]
  $[2 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; enlist ts 1]; ts 1;
    `bad]};

/ Two arguments of the same type; returns `boolean.  LIKE
.aqc.fn.sig.selfAndSelfToBool:{[ts]
  $[2 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; enlist ts 1]; `boolean;
    `bad]};

/ Two arguments, a number and a number or boolean; returns `numeric.
/ AVGS(n, x), SUMS(n, x), ...
.aqc.fn.sig.numAndBoolOrNumToNum:{[ts]
  $[2 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.num] and .aqc.tc.consistent[ts 1; .aqc.tc.numAndBool]; `numeric;
    `bad]};

/ Same check; returns the type of the second argument.  MAXS(n, x), MINS(n, x)
.aqc.fn.sig.numAndBoolOrNumToSelf:{[ts]
  $[2 <> count ts; `bad;
    .aqc.tc.consistent[ts 0; .aqc.tc.num] and .aqc.tc.consistent[ts 1; .aqc.tc.numAndBool]; ts 1;
    `bad]};

/ The rest are written out inside FunctionInfo.scala for one built-in each.

/ COUNT: one argument of any type; returns `numeric.
.aqc.fn.sig.anyToNum:{[ts] $[1 <> count ts; `bad; `numeric]};

/ NULL: one argument of any type; returns `boolean.
.aqc.fn.sig.anyToBool:{[ts] $[1 <> count ts; `bad; `boolean]};

/ IN: a value, then the values to look for, all of the value's type;
/ returns `boolean. (x IN (1, 2) is the call IN(x, 1, 2).)
/   inValues[`numeric`numeric`unknown]   is `boolean
/   inValues[`numeric`string]            is `bad
.aqc.fn.sig.inValues:{[ts]
  $[0 = count ts; `bad;
    .aqc.tc.allConsistent[1 _ ts; enlist ts 0]; `boolean;
    `bad]};

/ BETWEEN: any number of numeric arguments (even none); returns `boolean.
.aqc.fn.sig.allNumToBool:{[ts] $[.aqc.tc.allConsistent[ts; .aqc.tc.num]; `boolean; `bad]};

/ MAX, MIN: one or more numeric or boolean arguments. Returns `boolean if
/ every argument may be a boolean, otherwise `numeric.
/   maxMin[`boolean`unknown]   is `boolean
/   maxMin[`boolean`numeric]   is `numeric
.aqc.fn.sig.maxMin:{[ts]
  $[0 = count ts; `bad;
    not .aqc.tc.allConsistent[ts; .aqc.tc.numAndBool]; `bad;
    .aqc.tc.allConsistent[ts; .aqc.tc.bool]; `boolean;
    `numeric]};

/ OR (the function, not the operator): two or more boolean arguments;
/ returns `boolean.
.aqc.fn.sig.orArgs:{[ts]
  $[2 > count ts; `bad;
    .aqc.tc.allConsistent[ts; .aqc.tc.bool]; `boolean;
    `bad]};

/ SHOW: anything at all, even no arguments; returns `unit.
.aqc.fn.sig.showArgs:{[ts] `unit};

/ LIST: one or more arguments of any type; returns `unknown.
.aqc.fn.sig.listArgs:{[ts] $[0 = count ts; `bad; `unknown]};


/ ---------------------------------------------------------------------------
/ The built-in functions
/ ---------------------------------------------------------------------------

/ One row per built-in, in Scala's order (FunctionInfo.normal, then
/ FunctionInfo.orderDependent). Columns: name, signatures (tried in order),
/ orderDependent, remOrderDependence, usesAggregate.
.aqc.fn.builtinRows:(
  / not order-dependent
  (`ABS;     enlist `numToNum;                           0b; 0b; 0b);
  (`AVG;     enlist `boolOrNumToNum;                     0b; 1b; 1b);
  (`COUNT;   enlist `anyToNum;                           0b; 1b; 1b);
  (`FILL;    enlist `selfAndSelfToSelf;                  0b; 0b; 0b);
  (`IN;      enlist `inValues;                           0b; 0b; 0b);
  (`LIKE;    enlist `selfAndSelfToBool;                  0b; 0b; 0b);
  (`BETWEEN; enlist `allNumToBool;                       0b; 0b; 0b);
  (`MAX;     enlist `maxMin;                             0b; 1b; 1b);
  (`MIN;     enlist `maxMin;                             0b; 1b; 1b);
  (`NOT;     enlist `boolToBool;                         0b; 0b; 0b);
  (`NULL;    enlist `anyToBool;                          0b; 0b; 0b);
  (`OR;      enlist `orArgs;                             0b; 0b; 0b);
  (`PRD;     enlist `boolOrNumToNum;                     0b; 1b; 1b);
  (`SQRT;    enlist `numToNum;                           0b; 0b; 0b);
  (`SUM;     `numToNum`boolToNum;                        0b; 1b; 1b);
  (`SHOW;    enlist `showArgs;                           0b; 0b; 0b);
  (`LIST;    enlist `listArgs;                           0b; 0b; 0b);
  / order-dependent: Scala's odBuiltIn sets orderDependent and usesAggregate
  (`AVGS;    `boolOrNumToNum`numAndBoolOrNumToNum;       1b; 0b; 1b);
  (`DELTAS;  enlist `numToNum;                           1b; 0b; 1b);
  (`DROP;    enlist `numAndSelfToSelf;                   1b; 0b; 1b);
  (`FILLS;   `selfToSelf`selfAndSelfToSelf;              1b; 0b; 1b);
  (`FIRST;   `selfToSelf`numAndSelfToSelf;               1b; 0b; 1b);
  (`LAST;    `selfToSelf`numAndSelfToSelf;               1b; 0b; 1b);
  (`MAXS;    `boolOrNumToSelf`numAndBoolOrNumToSelf;     1b; 0b; 1b);
  (`MINS;    `boolOrNumToSelf`numAndBoolOrNumToSelf;     1b; 0b; 1b);
  (`NEXT;    `selfToSelf`numAndSelfToSelf;               1b; 0b; 1b);
  (`PREV;    `selfToSelf`numAndSelfToSelf;               1b; 0b; 1b);
  (`PRDS;    `boolOrNumToNum`numAndBoolOrNumToNum;       1b; 0b; 1b);
  (`SUMS;    `boolOrNumToNum`numAndBoolOrNumToNum;       1b; 0b; 1b);
  (`VARS;    `boolOrNumToNum`numAndBoolOrNumToNum;       1b; 0b; 1b));

/ makeRow[r]
/   One function row (a dictionary) from one item of builtinRows.
/     makeRow (`ABS; enlist `numToNum; 0b; 0b; 0b)
/   is
/     `name`sigs`orderDependent`remOrderDependence`usesAggregate`nargs!
/       (`ABS; enlist `numToNum; 0b; 0b; 0b; 0N)
.aqc.fn.makeRow:{[r]
  `name`sigs`orderDependent`remOrderDependence`usesAggregate`nargs!r,0N};

/ The table of built-ins, keyed by name: .aqc.fn.builtins `SUM gives the
/ SUM row (without its name). The rows are made one by one with makeRow;
/ q turns a list of dictionaries with the same keys into a table, and 1!
/ makes the first column (name) the key.
.aqc.fn.builtins:1!.aqc.fn.makeRow each .aqc.fn.builtinRows;


/ ---------------------------------------------------------------------------
/ The table for one program: built-ins plus the program's UDFs
/ ---------------------------------------------------------------------------

/ env[prog]
/   The function table for a parsed program: the built-ins, plus one row
/   per UDF (FUNCTION f(x, y) {...}) defined anywhere in the program. A UDF
/   is known in the whole program, also before its definition, and a later
/   definition replaces an earlier one with the same name.
/   prog: list of top-level nodes (what .aqc.gen.parseText returns)
/   (Scala: TypeChecker.apply, through FunctionInfo.apply)
.aqc.fn.env:{[prog]
  env:.aqc.fn.builtins;
  k:0;
  while[k < count prog;
    if[`UDF ~ .aqc.nodes.name prog k; env:.aqc.fn.addUdf[env; prog k]];
    k+:1];
  env};

/ addUdf[env; u]
/   env with a row for UDF node u. The type checker only checks a UDF's
/   number of arguments; it never knows its result type (always `unknown)
/   and leaves the order flags off (the order analysis sets them itself).
/   (Scala: TypeChecker.apply's ctFunArgs)
.aqc.fn.addUdf:{[env;u]
  r:`name`sigs`orderDependent`remOrderDependence`usesAggregate`nargs!
    (`$u`n; `symbol$(); 0b; 0b; 0b; count u`args);
  env upsert r};   / upsert: replaces the row with this name, or adds one


/ ---------------------------------------------------------------------------
/ Looking up and calling
/ ---------------------------------------------------------------------------

/ known[env; f]
/   Is there a row for function name f (a symbol)?
.aqc.fn.known:{[env;f] f in (0!env)`name};   / 0! turns the keyed table back into a plain one

/ resultType[env; f; ts]
/   The type a call to known function f returns when its arguments have
/   the types ts, or `bad when the call does not fit.
/     resultType[env; `SQRT; enlist `numeric]   is `numeric
/     resultType[env; `SQRT; enlist `string]    is `bad
/     resultType[env; `f; `unknown`unknown]     is `unknown  (if UDF f takes 2)
/   (Scala: info(f).signature.lift(argTypes))
.aqc.fn.resultType:{[env;f;ts]
  r:env f;
  $[not null r`nargs;
    $[r[`nargs] = count ts; `unknown; `bad];   / a UDF: only the count matters
    .aqc.fn.trySigs[r`sigs; ts]]};

/ trySigs[sigs; ts]
/   Try the signatures named in sigs in order; the first answer that is
/   not `bad is the result. (Scala: sig1 orElse sig2)
.aqc.fn.trySigs:{[sigs;ts]
  k:0;
  while[k < count sigs;
    sigFun:.aqc.fn.sig sigs k;
    result:sigFun ts;
    if[not `bad = result; :result];
    k+:1];
  `bad};
