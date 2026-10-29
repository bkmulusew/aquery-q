/ trigger.q - q code for CREATE TRIGGER and DROP TRIGGER.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/codegen/
/ KdbGenerator.scala: genTrigger and the functions it calls
/ (genTriggerDefault, genTriggerInsertQueryDefault,
/ genTransitionUpdateTrigger, genTransitionDeleteTrigger,
/ toTransitionUpdatePlan, toTransitionDeletePlan and their helpers), and
/ genDropTrigger. As elsewhere, Scala's odd corners are copied on purpose
/ (SCALA QUIRK) and its bugs are fixed (FIXED).

/ WHAT THE CODE LOOKS LIKE
/ A trigger becomes a q function .trg.gen_NAME_N (N is the query
/ number) that base.q's trigger runtime (.trg.*) calls with the changed
/ table, the event and a context dictionary ctx:
/     CREATE TRIGGER trg AFTER UPDATE ON t1 DO STATEMENT
/   becomes
/     .trg.gen_trg_0:{[tbl;evt;ctx]
/      ctx:.trg.ctxSet[ctx;`triggerName;`trg];
/      ... (4 more ctx lines: table, event, timing, REFERENCING text)
/      (the statement's code)
/      ctx
/      };
/      .trg.register[`t1;`update;`after;`trg;100;`.trg.gen_trg_0];
/ REFERENCING NEW TABLE AS x (or OLD TABLE AS x) makes x a table of the
/ changed rows inside the function.
/ Some AFTER UPDATE/DELETE triggers that copy changed rows into another
/ table by key ("transition" triggers, see transitionPlan) get special
/ code that joins the two tables and calls .trg.syncMappedUpdateRowsTo or
/ .trg.syncMappedDeleteRowsFrom.


/ ---------------------------------------------------------------------------
/ Names and context lines
/ ---------------------------------------------------------------------------

/ The q symbols for the trigger's event and timing.
.aqc.gen.eventNames:`InsertEvent`UpdateEvent`DeleteEvent!("insert";"update";"delete");
.aqc.gen.timingNames:`Before`After!("before";"after");

/ refsText[refs]
/   The REFERENCING clause as a q string for the context, or "()" if
/   there is none.
/     REFERENCING NEW TABLE AS ins   gives   "\"NEW TABLE AS ins\""
.aqc.gen.refsText:{[refs]
  if[0 = count refs; :"()"];
  parts:();
  k:0;
  while[k < count refs;
    r:refs k;
    kind:$[`NewTableRef ~ r`kind; "NEW"; "OLD"];
    parts,:enlist kind," TABLE AS ",.aqc.gen.str r`alias;
    k+:1];
  text:.aqc.gen.join[", "; parts];
  / a " in an alias would end the q string: write it as \"
  text:raze {[ch] $[ch = "\""; "\\\""; enlist ch]} each text;
  "\"",text,"\""};

/ rowsSource[kind; event; timing]
/   The base.q expression for the rows a NEW/OLD TABLE stands for (Scala:
/   triggerRowsExpr and getTriggerRefRowsExpr), or "" when this kind of
/   table does not exist for the event and timing.
.aqc.gen.rowsSource:{[kind;event;timing]
  if[(kind = `NewTableRef) and event = `InsertEvent; :".trg.rows ctx"];
  if[(kind = `OldTableRef) and event = `UpdateEvent; :".trg.oldRows ctx"];
  if[(kind = `NewTableRef) and (event = `UpdateEvent) and timing = `After; :".trg.affectedResultRows ctx"];
  if[(kind = `OldTableRef) and event = `DeleteEvent; :".trg.oldRows ctx"];
  ""};

/ refBindings[t]
/   One line per NEW/OLD TABLE of trigger t that makes its alias a table
/   (Scala: genTriggerRefBindings), joined with "\n ".
/     REFERENCING NEW TABLE AS ins (AFTER INSERT)   gives
/     "ins:.aq.initTable[.trg.rows ctx;\"ins\";0b];"
.aqc.gen.refBindings:{[t]
  lines:();
  k:0;
  while[k < count t`refs;
    r:(t`refs) k;
    rows:.aqc.gen.rowsSource[r`kind; t`event; t`time];
    alias:.aqc.gen.str r`alias;
    if[0 < count rows;
      lines,:enlist alias,":.aq.initTable[",rows,";\"",alias,"\";0b];"];
    k+:1];
  .aqc.gen.join["\n "; lines]};

/ wrapTrigger[w; body]
/   The whole trigger function around body (its code, already indented),
/   and the line that registers it. w is a dictionary with the trigger's
/   names: func, trigger, table, event, timing, refs (all q code).
.aqc.gen.wrapTrigger:{[w;body]
  ctxLine:{[field;v] " ctx:.trg.ctxSet[ctx;`",field,";",v,"];"};
  lines:(w[`func],":{[tbl;evt;ctx]";
    ctxLine["triggerName"; w`trigger];
    ctxLine["triggerTable"; w`table];
    ctxLine["triggerEvent"; w`event];
    ctxLine["triggerTiming"; w`timing];
    ctxLine["triggerRefs"; w`refs];
    body;
    " ctx";
    " };";
    " .trg.register[",w[`table],";",w[`event],";",w[`timing],";",w[`trigger],";100;",(.aqc.gen.sym w`func),"];");
  .aqc.gen.join["\n"; lines]};


/ ---------------------------------------------------------------------------
/ Editing the code of the trigger's statement
/ ---------------------------------------------------------------------------

/ javaTrim[text]
/   text without the characters up to " " (spaces, line breaks, ...) at
/   its start and end, as Java's String.trim (q's trim only removes
/   spaces).
/     javaTrim "\n {a}\n "   is "{a}"
.aqc.gen.javaTrim:{[text]
  keep:where text > " ";                      / positions of the other characters
  if[0 = count keep; :""];
  (first keep) _ (1 + last keep) # text};

/ unwrapBlock[body]
/   If body (trimmed) is a lambda called at once, "{...}[];", the code
/   inside it, trimmed (Scala: unwrapImmediateBlock); else body unchanged.
/     unwrapBlock "{\n a;\n }[];"   is "a;"
.aqc.gen.unwrapBlock:{[body]
  trimmed:.aqc.gen.javaTrim body;
  n:count trimmed;
  if[(n >= 5) and ("{" = first trimmed) and "}[];" ~ (neg 4) # trimmed;
    :.aqc.gen.javaTrim -4 _ 1 _ trimmed];       / drop "{" and "}[];"
  body};

/ injectAfterInit[body; injected]
/   body with injected put on a new line after its first
/   ".aq.initQueryState[];" (Scala: injectAfterInit), so the NEW/OLD
/   tables exist before the statement's query runs. No marker: injected
/   goes first. Nothing to inject: body unchanged.
.aqc.gen.injectAfterInit:{[body;injected]
  if[0 = count injected; :body];
  marker:".aq.initQueryState[];";
  / where the marker starts (not with ss: [ and ] are special to ss)
  starts:where body = first marker;
  isMarker:{[body;marker;i] marker ~ (count marker) # i _ body}[body; marker];
  found:starts where isMarker each starts;
  if[0 = count found; :injected,"\n",body];
  at:(first found) + count marker;
  (at # body),"\n ",injected,at _ body};


/ ---------------------------------------------------------------------------
/ Transition triggers (Scala: toTransitionUpdatePlan, toTransitionDeletePlan)
/ ---------------------------------------------------------------------------

/ A transition trigger copies the changed rows, the NEW or OLD TABLE x,
/ into another table d, matching rows by key:
/     CREATE TRIGGER s AFTER UPDATE ON t REFERENCING NEW TABLE AS x
/     DO UPDATE d SET qty = x.qty WHERE d.id = x.id
/ transitionPlan checks that the statement has this shape and returns a
/ dictionary with what the code needs (Scala: TransitionUpdatePlan and
/ TransitionDeletePlan):
/     dest     d                     alias   x
/     kind     `NewTableRef or `OldTableRef
/     keys     d's key columns       ("id")
/     filters  the WHERE conditions
/     sets     (column; expression) pairs of the SET (UPDATE only)
/ or (::) (q's "nothing") when it does not.

/ The expression nodes exprUsesOnlyTables accepts (and ColumnAccess of an
/ allowed table). Anything else (*, ROWID, x[even], ...) makes it false.
.aqc.gen.plainExprs:`IntLit`FloatLit`StringLit`DateLit`TimestampLit`BooleanLit,
  `Id`BinExpr`UnExpr`FunCall`Case`IfThen;

/ usesOnlyTables[e; allowed]
/   Does every table.column in expression e name a table in allowed (a
/   list of strings)? (Scala: exprUsesOnlyTables)
.aqc.gen.usesOnlyTables:{[e;allowed]
  subs:.aqc.nodes.allSubExpressions e;
  k:0;
  while[k < count subs;
    s:subs k;
    n:.aqc.nodes.name s;
    / (any allowed ~\: x: is x one of the strings in allowed?)
    ok:$[n = `ColumnAccess; any allowed ~\: .aqc.gen.str s`t; n in .aqc.gen.plainExprs];
    if[not ok; :0b];
    k+:1];
  1b};

/ aliasesIn[e; aliases]
/   The transition aliases that expression e uses as table.column, each
/   once, in Scala's order. aliases maps alias (symbol) to kind.
.aqc.gen.aliasesIn:{[e;aliases]
  subs:.aqc.nodes.allSubExpressions e;
  found:`symbol$();
  k:0;
  while[k < count subs;
    s:subs k;
    if[`ColumnAccess ~ .aqc.nodes.name s;
      a:`$.aqc.gen.str s`t;
      if[(a in key aliases) and not a in found; found,:a]];
    k+:1];
  found};

/ setInfo[dest; aliases; assign]
/   For SET c = e (assign is Tuple(c, e)): (c; alias; e) when e uses
/   exactly one transition alias and no other table but dest; else (::)
/   (Scala: extractTransitionAssign).
.aqc.gen.setInfo:{[dest;aliases;assign]
  e:assign`_2;
  used:.aqc.gen.aliasesIn[e; aliases];
  if[not 1 = count used; :(::)];
  if[not .aqc.gen.usesOnlyTables[e; (dest; string first used)]; :(::)];
  (.aqc.gen.str assign`_1; first used; e)};

/ keyInfo[dest; aliases; e]
/   For a WHERE condition d.k = x.k2 (either way round), with d = dest and
/   x a transition alias: (k; x); else (::) (Scala:
/   extractTransitionKeyPair).
.aqc.gen.keyInfo:{[dest;aliases;e]
  if[not `BinExpr ~ .aqc.nodes.name e; :(::)];
  if[not `Eq ~ e`op; :(::)];
  isCol:{[x] `ColumnAccess ~ .aqc.nodes.name x};
  l:e`l;
  r:e`r;
  if[not (isCol l) and isCol r; :(::)];
  / d.k = x.k2, or x.k2 = d.k
  pair:$[dest ~ .aqc.gen.str l`t; .aqc.nodes.two[l; r]; dest ~ .aqc.gen.str r`t; .aqc.nodes.two[r; l]; ()];
  if[0 = count pair; :(::)];
  a:`$.aqc.gen.str pair[1]`t;
  if[not a in key aliases; :(::)];
  (.aqc.gen.str pair[0]`c; a)};

/ transitionPlan[t]
/   The plan dictionary for trigger t if it is a transition trigger, else
/   (::). Its body must be an UPDATE or DELETE ... WHERE, the trigger must
/   be AFTER and have a NEW/OLD TABLE, and every SET and WHERE must use
/   one and the same alias and only the target table besides it.
.aqc.gen.transitionPlan:{[t]
  body:t`body;
  isUpdate:`Update ~ body`node;
  if[not t[`time] = `After; :(::)];
  if[0 = count t`refs; :(::)];
  / alias -> kind (later REFERENCING entries win, as Scala's toMap)
  aliases:(`symbol$())!`symbol$();
  k:0;
  while[k < count t`refs;
    r:(t`refs) k;
    aliases[`$.aqc.gen.str r`alias]:r`kind;
    k+:1];
  dest:.aqc.gen.str body`t;
  sets:();
  if[isUpdate;
    k:0;
    while[k < count body`assigns;
      info:.aqc.gen.setInfo[dest; aliases; (body`assigns) k];
      if[info ~ (::); :(::)];
      sets,:enlist info;
      k+:1];
    if[(0 < count body`groupby) or (0 < count body`having) or 0 < count body`order; :(::)];
    filters:body`where];
  if[not isUpdate;
    if[(0 < count body`order) or (0 < count body`groupby) or 0 < count body`having; :(::)];
    filters:$[`Left ~ (body`del)`node; (); (body`del)`value];
    if[0 = count filters; :(::)]];
  / (keyPairs, not keys: L does not allow a q built-in as a name)
  keyPairs:();
  k:0;
  while[k < count filters;
    info:.aqc.gen.keyInfo[dest; aliases; filters k];
    if[not info ~ (::); keyPairs,:enlist info];
    k+:1];
  if[0 = count keyPairs; :(::)];
  keyAliases:distinct {[x] x 1} each keyPairs;
  if[not 1 = count keyAliases; :(::)];
  alias:first keyAliases;
  k:0;
  while[k < count filters;
    if[not .aqc.gen.usesOnlyTables[filters k; (dest; string alias)]; :(::)];
    k+:1];
  usedAliases:distinct keyAliases,{[x] x 1} each sets;
  if[not 1 = count usedAliases; :(::)];
  keyCols:distinct {[x] x 0} each keyPairs;
  `dest`alias`kind`keys`filters`sets!(dest; string alias; aliases alias; keyCols; filters; sets)};


/ ---------------------------------------------------------------------------
/ The three kinds of trigger code
/ ---------------------------------------------------------------------------

/ transitionCode[t; p]
/   The body of a transition trigger with plan p (Scala:
/   genTransitionUpdateTrigger and genTransitionDeleteTrigger): make the
/   alias's table, join it with the target table, keep the rows WHERE
/   matches, select the key columns (and the SET values), and hand the
/   result to .trg.syncMappedUpdateRowsTo (UPDATE) or
/   .trg.syncMappedDeleteRowsFrom (DELETE).
.aqc.gen.transitionCode:{[t;p]
  isUpdate:`Update ~ (t`body)`node;
  rows:.aqc.gen.rowsSource[p`kind; t`event; t`time];
  if[0 = count rows; '"codegen: unsupported transition-table rows source for trigger"];
  dest:p`dest;
  alias:p`alias;
  / SELECT d.k AS k, ..., e AS c, ... FROM d, x WHERE filters
  items:();
  k:0;
  while[k < count p`keys;
    key1:(p`keys) k;
    items:.aqc.ast.append[items; .aqc.ast.tuple (.aqc.ast.columnAccess[dest; key1]; .aqc.ast.some key1)];
    k+:1];
  k:0;
  while[k < count p`sets;
    s:(p`sets) k;                             / (column; alias; expression)
    items:.aqc.ast.append[items; .aqc.ast.tuple (s 2; .aqc.ast.some s 0)];
    k+:1];
  joined:.aqc.ast.join[`Cross; .aqc.ast.table[dest; .aqc.ast.some dest];
    .aqc.ast.table[alias; .aqc.ast.some alias]; ()];
  projected:.aqc.ast.project[.aqc.ast.filter[joined; p`filters]; items];
  .aqc.gen.cleanQueryEnv[];
  rowCode:.aqc.gen.plan projected;
  rowTable:.aqc.gen.get `currTable;
  keyList:.aqc.gen.symList p`keys;
  sync:$[isUpdate;
    ".trg.syncMappedUpdateRowsTo[",rowTable,";",(.aqc.gen.sym dest),";",keyList,";",keyList,";",(.aqc.gen.symDict p`sets),"];";
    ".trg.syncMappedDeleteRowsFrom[",rowTable,";",(.aqc.gen.sym dest),";",keyList,";",keyList,"];"];
  .aqc.gen.join["\n"; (" ",.aqc.gen.initQueryState;
    " ",alias,":.aq.initTable[",rows,";\"",alias,"\";0b];";
    " ",rowCode;
    " ",sync)]};

/ symDict[sets]
/   The dictionary from each SET column to itself, as q code (Scala:
/   toKdbSymDict).
/     one column a     gives "(enlist `a)!enlist `a"
/     columns a, b     gives "`a`b!`a`b"
.aqc.gen.symDict:{[sets]
  names:();
  k:0;
  while[k < count sets; names,:enlist (sets k) 0; k+:1];
  if[1 = count names; :"(enlist ",(.aqc.gen.sym names 0),")!enlist ",.aqc.gen.sym names 0];
  (.aqc.gen.symList names),"!",.aqc.gen.symList names};

/ insertQueryCode[t]
/   The body of a trigger whose statement is INSERT INTO n ... QUERY
/   and that has a NEW/OLD TABLE (Scala: genTriggerInsertQueryDefault):
/   the query's result goes into aq__insert_src, which is then inserted.
/   FIXED: Scala writes no ";" after the .aq.insert, so q read it and the
/   next line, " ctx", as one expression.
.aqc.gen.insertQueryCode:{[t]
  i:t`body;
  queryCode:.aqc.gen.queryTo[(i`src)`value; {[r] "aq__insert_src:",r,";"}];
  n:.aqc.gen.str i`n;
  sorted:n;
  if[0 < count i`order;
    sortPlan:.aqc.gen.plainTable[n; i`order];
    sorted:"\n {\n ",(.aqc.gen.planCode[sortPlan; {[r] r}; 1b])," \n }[]"];
  modifier:.aqc.gen.symList i`modifier;
  body:queryCode,"\n .aq.insert[",(.aqc.gen.sym n),";",sorted,";",modifier,";aq__insert_src];";
  " ",.aqc.gen.injectAfterInit[body; .aqc.gen.refBindings t]};

/ defaultCode[t]
/   The body of any other trigger (Scala: genTriggerDefault): the
/   statement's own code, without its {...}[]; wrapper, with the NEW/OLD
/   tables made after its first .aq.initQueryState[].
/   FIXED: the code of an INSERT, of an UPDATE or DELETE (once unwrapped)
/   and of a query does not end with ";", and Scala adds none, so q read
/   it and the " ctx" line after it as one expression. endStatement adds
/   the ";".
.aqc.gen.defaultCode:{[t]
  body:.aqc.gen.endStatement .aqc.gen.unwrapBlock .aqc.gen.topLevel t`body;
  " ",.aqc.gen.injectAfterInit[body; .aqc.gen.refBindings t]};

/ endStatement[code]
/   code with a ";" at the end, unless it already ends with one.
/     endStatement ".aq.insert[`t;t;();x]"   is ".aq.insert[`t;t;();x];"
.aqc.gen.endStatement:{[code] $[";" = last code; code; code,";"]};


/ ---------------------------------------------------------------------------
/ The statements
/ ---------------------------------------------------------------------------

/ trigger[t]
/   PUBLIC. CREATE TRIGGER name timing event ON table [REFERENCING ...]
/   DO statement (Scala: genTrigger). Uses up one query number, for the
/   function's name.
.aqc.gen.trigger:{[t]
  id:.aqc.gen.get `queryId;
  .aqc.gen.set[`queryId; id + 1];
  name:.aqc.gen.str t`name;
  w:`func`trigger`table`event`timing`refs!(
    ".trg.gen_",name,"_",string id;
    .aqc.gen.sym name;
    .aqc.gen.sym t`table;
    .aqc.gen.sym .aqc.gen.eventNames t`event;
    .aqc.gen.sym .aqc.gen.timingNames t`time;
    .aqc.gen.refsText t`refs);
  bodyName:.aqc.nodes.name t`body;
  p:$[bodyName in `Update`Delete; .aqc.gen.transitionPlan t; (::)];
  / (q's and is not lazy, so the src test is inside $[...])
  isInsertQuery:$[(bodyName = `Insert) and 0 < count t`refs; `Right ~ ((t`body)`src)`node; 0b];
  code:$[not p ~ (::); .aqc.gen.transitionCode[t; p];
    isInsertQuery; .aqc.gen.insertQueryCode t;
    .aqc.gen.defaultCode t];
  .aqc.gen.wrapTrigger[w; code]};

/ dropTrigger[d]
/   PUBLIC. DROP TRIGGER name (Scala: genDropTrigger).
.aqc.gen.dropTrigger:{[d] ".trg.drop[",(.aqc.gen.sym d`name),"];"};
