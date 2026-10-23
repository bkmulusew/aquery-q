/ dot.q - print a program as a Graphviz (DOT) graph: the compiler's -p.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/ast/: Dot.scala
/ (declareNode, declareEdge, strList, toGraph) and the dotify method of
/ every node class (expr.scala, query.scala, data.scala, udf.scala,
/ trigger.scala, types.scala, VerbatimCode.scala, TopLevel.scala).
/ The output must be byte for byte what `aquery.jar -p` prints, so Scala's
/ odd corners are copied on purpose (each one is marked SCALA QUIRK).

/ HOW THE GRAPH IS BUILT
/ Every graph node gets a number. Each dotify function takes the first
/ free number, id, and returns a pair (text; next free number). For a
/ plan or statement, text is DOT lines, e.g. for SELECT a FROM t with id 3:
/     3 [label="project a"];
/     3 -> 4;
/     4 [label="t"];
/ and the pair is (those lines; 5).
/ Expressions are not graph nodes: their dotify gives a label to put
/ inside a node's label ("a+1", "f(x,y)"). Only IfThen and Case make real
/ node lines, and those end up inside a label too (a SCALA QUIRK).

/ Strings in the tree may be char atoms when they are one character long
/ (see src/parse/ast.q), so every string field goes through .aqc.dot.str.


/ ---------------------------------------------------------------------------
/ Text helpers
/ ---------------------------------------------------------------------------

/ str[x]
/   x as a string: a one-character string may be stored as a char atom.
/     str "a"   is enlist "a"     str "ab"   is "ab"
.aqc.dot.str:{[x] $[-10h = type x; enlist x; x]};

/ join[sep; strs]
/   The strings strs with sep between them (Scala: strs.mkString(sep)).
/     join[", "; ("a";"b";"c")]   is "a, b, c"
/   A loop, not sep sv strs: sv fails in L when sep is one character.
.aqc.dot.join:{[sep;strs]
  out:"";
  k:0;
  while[k < count strs;
    if[k > 0; out,:sep];
    out,:.aqc.dot.str strs k;
    k+:1];
  out};

/ node[id; label]
/   One DOT node line (Scala: Dot.declareNode).
/     node[3; "t"]   is "3 [label=\"t\"];\n"
/   SCALA QUIRK: the label is not escaped, so a " or a newline in it is
/   copied as it is (the result is not always valid DOT).
.aqc.dot.node:{[id;label] (string id)," [label=\"",label,"\"];\n"};

/ edge[src; dest]
/   One DOT edge line (Scala: Dot.declareEdge).
/     edge[3; 4]   is "3 -> 4;\n"
.aqc.dot.edge:{[src;dest] (string src)," -> ",(string dest),";\n"};

/ lines[text]
/   text split at each "\n", without the "\n"s. A final "\n" does not
/   start another (empty) line.
/     lines "a\nb\n"   is ("a";"b")
.aqc.dot.lines:{[text]
  out:();
  current:"";
  k:0;
  while[k < count text;
    $["\n" = text k;
      [out,:enlist current; current:""];
      current,:text k];
    k+:1];
  if[0 < count current; out,:enlist current];
  out};


/ ---------------------------------------------------------------------------
/ Expressions (Scala: dotify in expr.scala)
/ ---------------------------------------------------------------------------

/ The text Scala prints for each binary operator (BinExpr.dotify).
.aqc.dot.binOps:`Plus`Minus`Times`Div`Exp`Lt`Le`Gt`Ge`Eq`Neq`Land`Lor!
  ("+";"-";"*";"/";"pow";"<";"<=";">";">=";"==";"!=";"&";"|");

/ expr[e; id]
/   PUBLIC. (label; next free id) for expression e (Scala: e.dotify(id)).
/     expr[<a + 1>; 7]       is ("a+1"; 8)
/     expr[<f(x, 2.0)>; 7]   is ("f(x,2.0)"; 8)
/   Every expression uses only id itself, so next is id + 1, except Case,
/   which numbers its parts (see caseExpr).
.aqc.dot.expr:{[e;id]
  n:.aqc.nodes.name e;
  if[n = `Id; :(.aqc.dot.str e`v; id + 1)];
  / numbers and booleans as Scala prints them (2.0, true); the other
  / literals print their text as it is
  if[n in `IntLit`FloatLit`BooleanLit; :(.aqc.ast.scalarText e`v; id + 1)];
  if[n in `StringLit`DateLit`TimestampLit; :(.aqc.dot.str e`v; id + 1)];
  if[n = `TableColumnValue; :((.aqc.dot.str e`t),"(\"",(.aqc.dot.str e`c),"\")"; id + 1)];
  if[n = `RowId; :("ROWID"; id + 1)];
  if[n = `WildCard; :(enlist "*"; id + 1)];
  if[n = `ColumnAccess; :((.aqc.dot.str e`t),".",.aqc.dot.str e`c; id + 1)];
  / a+b: no spaces around the operator
  if[n = `BinExpr;
    :((.aqc.dot.label[e`l; id]),(.aqc.dot.binOps e`op),.aqc.dot.label[e`r; id]; id + 1)];
  if[n = `UnExpr;
    :(($[`Not = e`op; "!"; "-"]),.aqc.dot.label[e`v; id]; id + 1)];
  if[n = `FunCall;
    :((.aqc.dot.str e`f),"(",(.aqc.dot.join[","; .aqc.dot.labels[e`args; id]]),")"; id + 1)];
  if[n = `ArrayIndex; :(.aqc.dot.arrayIndex e; id + 1)];
  / SCALA QUIRK: IfThen gives a whole node line as its "label"
  if[n = `IfThen;
    text:"if (",(.aqc.dot.label[e`c; id]),") then ",.aqc.dot.label[e`t; id];
    :(.aqc.dot.node[id; text]; id + 1)];
  if[n = `Case; :.aqc.dot.caseExpr[e; id]];
  '"dot: not an expression: ",string n};

/ label[e; id]
/   Just the label of expression e (the first part of expr[e; id]).
.aqc.dot.label:{[e;id] first .aqc.dot.expr[e; id]};

/ labels[es; id]
/   The label of each expression in the list es, all with the same id
/   (Scala: es.map(_.dotify(id)._1)).
.aqc.dot.labels:{[es;id]
  out:();
  k:0;
  while[k < count es;
    out,:enlist .aqc.dot.label[es k; id];
    k+:1];
  out};

/ arrayIndex[e]
/   The label of e[EVEN], e[ODD] or e[EVERY n]: "x[even]", "x[every 3]".
/   SCALA QUIRK: the inner expression is labelled with id 0, whatever id
/   the ArrayIndex itself has (Scala: f = e.dotify(0)._1).
.aqc.dot.arrayIndex:{[e]
  ix:e`ix;
  ixText:$[`Even ~ ix; "even";
    `Odd ~ ix; "odd";
    "every ",string ix`v];          / Every(n)
  (.aqc.dot.label[e`e; 0]),"[",ixText,"]"};

/ caseExpr[e; id]
/   (text; next) for CASE [x] WHEN ... THEN ... [ELSE z] END. Unlike other
/   expressions this makes node lines, numbered from id:
/     id          "case"
/     id + 1      the value after CASE, if there is one, with an edge
/     next ids    one node per WHEN (an IfThen), each with an edge
/     next id     the ELSE value, if there is one, with an edge
/   SCALA QUIRK: each WHEN node comes before its edge; the CASE value and
/   the ELSE value come before theirs too.
.aqc.dot.caseExpr:{[e;id]
  text:.aqc.dot.node[id; "case"];
  whenId:id + 1;
  if[not `None ~ e`cond;
    r:.aqc.dot.expr[(e`cond)`value; id + 1];
    text,:.aqc.dot.node[id + 1; r 0],.aqc.dot.edge[id; id + 1];
    whenId:r 1];
  / one node per WHEN (Scala: Dot.strList over the IfThens)
  nextId:whenId;
  k:0;
  whens:e`when;
  while[k < count whens;
    r:.aqc.dot.expr[whens k; nextId];
    text,:(r 0),.aqc.dot.edge[id; nextId];
    nextId:r 1;
    k+:1];
  if[not `None ~ e`e;
    r:.aqc.dot.expr[(e`e)`value; nextId];
    text,:.aqc.dot.node[nextId; r 0],.aqc.dot.edge[id; nextId];
    nextId:r 1];
  (text; nextId)};


/ ---------------------------------------------------------------------------
/ Plans (Scala: RelAlg.dotify in query.scala)
/ ---------------------------------------------------------------------------

/ named[e; alias; id]
/   The label of a projection or group "e" or "e as alias", where alias
/   is `None or Some(name).
.aqc.dot.named:{[e;alias;id]
  lbl:.aqc.dot.label[e; id];
  $[`None ~ alias; lbl; lbl," as ",.aqc.dot.str alias`value]};

/ namedList[tuples; id]
/   The named labels of a list of Tuple(expr, alias): ps of a Project or
/   gs of a GroupBy.
.aqc.dot.namedList:{[tuples;id]
  out:();
  k:0;
  while[k < count tuples;
    t:tuples k;
    out,:enlist .aqc.dot.named[t`_1; t`_2; id];
    k+:1];
  out};

/ withSource[id; label; source]
/   A node with one child plan: the node, an edge to id + 1, then the
/   child plan numbered from id + 1. Project, Filter, GroupBy, SortBy and
/   TopApply all look like this.
.aqc.dot.withSource:{[id;label;source]
  r:.aqc.dot.plan[source; id + 1];
  (.aqc.dot.node[id; label],(.aqc.dot.edge[id; id + 1]),r 0; r 1)};

/ sortLabel[os]
/   The label of an ASSUMING sort: "sort: Asc a, Desc t.b".
/   SCALA QUIRK: the expressions are labelled with id 1, not the node's id.
.aqc.dot.sortLabel:{[os]
  parts:();
  k:0;
  while[k < count os;
    o:os k;                                     / Tuple(Asc or Desc, expr)
    parts,:enlist (string o`_1)," ",.aqc.dot.label[o`_2; 1];
    k+:1];
  "sort: ",.aqc.dot.join[", "; parts]};

/ plan[r; id]
/   PUBLIC. (DOT lines; next free id) for plan node r, numbered from id.
.aqc.dot.plan:{[r;id]
  n:.aqc.nodes.name r;
  / SCALA QUIRK: projections are joined with " ," (space before comma)
  if[n = `Project;
    :.aqc.dot.withSource[id; "project ",.aqc.dot.join[" ,"; .aqc.dot.namedList[r`ps; id]]; r`t]];
  if[n = `Filter;
    :.aqc.dot.withSource[id; "where ",.aqc.dot.join[", "; .aqc.dot.labels[r`fs; id]]; r`t]];
  if[n = `GroupBy;
    lbl:"group-by ",.aqc.dot.join[" ,"; .aqc.dot.namedList[r`gs; id]];
    if[0 < count r`having; lbl,:" having ",.aqc.dot.join[", "; .aqc.dot.labels[r`having; id]]];
    :.aqc.dot.withSource[id; lbl; r`t]];
  if[n = `SortBy; :.aqc.dot.withSource[id; .aqc.dot.sortLabel r`os; r`t]];
  if[n = `TopApply; :.aqc.dot.withSource[id; .aqc.dot.str r`f; r`t]];
  if[n = `Table;
    alias:r`alias;
    lbl:(.aqc.dot.str r`n),$[`None ~ alias; ""; " as ",.aqc.dot.str alias`value];
    :(.aqc.dot.node[id; lbl]; id + 1)];
  if[n = `BottomApply;
    lbl:(.aqc.dot.str r`f),"(",(.aqc.dot.join[", "; .aqc.dot.labels[r`args; id]]),")";
    :(.aqc.dot.node[id; lbl]; id + 1)];
  if[n = `Join; :.aqc.dot.joinPlan[r; id]];
  '"dot: not a plan node: ",string n};

/ joinPlan[r; id]
/   (DOT lines; next free id) for a Join. Lines in Scala's order:
/     id         the join type, e.g. "InnerJoinUsing" or "Cross"
/     edge to the left plan, the left plan (from id + 1)
/     edge to the right plan, the right plan (after the left one)
/     edge to the conditions node, "conds: a, b" (after the right one)
/   SCALA QUIRK: the condition labels use the conditions node's id.
.aqc.dot.joinPlan:{[r;id]
  text:.aqc.dot.node[id; string r`jt];
  text,:.aqc.dot.edge[id; id + 1];
  left:.aqc.dot.plan[r`l; id + 1];
  rightId:left 1;
  text,:(left 0),.aqc.dot.edge[id; rightId];
  right:.aqc.dot.plan[r`r; rightId];
  condId:right 1;
  text,:(right 0),.aqc.dot.edge[id; condId];
  text,:.aqc.dot.node[condId; "conds: ",.aqc.dot.join[", "; .aqc.dot.labels[r`cond; condId]]];
  (text; condId + 1)};


/ ---------------------------------------------------------------------------
/ Statements (Scala: TopLevel.dotify and the classes it calls)
/ ---------------------------------------------------------------------------

/ query[q; id]
/   (DOT lines; next free id) for a whole query: a "full-query" node, then each
/   WITH query (a node "name(col1,col2)" with an edge to its plan), then
/   the main plan. Lines in Scala's order:
/     id             "full-query"
/     per WITH query, at k:  node k, edge id -> k, its plan (from k + 1),
/                            edge k -> k + 1
/     edge id -> main, the main plan
.aqc.dot.query:{[q;id]
  text:.aqc.dot.node[id; "full-query"];
  nextId:id + 1;
  locals:q`local;
  k:0;
  while[k < count locals;
    l:locals k;                       / Tuple(name, column names, plan)
    lbl:(.aqc.dot.str l`_1),"(",(.aqc.dot.join[","; l`_2]),")";
    text,:.aqc.dot.node[nextId; lbl],.aqc.dot.edge[id; nextId];
    r:.aqc.dot.plan[l`_3; nextId + 1];
    text,:(r 0),.aqc.dot.edge[nextId; nextId + 1];
    nextId:r 1;
    k+:1];
  main:.aqc.dot.plan[q`main; nextId];
  (text,(.aqc.dot.edge[id; nextId]),main 0; main 1)};

/ udfCommand[c]
/   The label of one command in a function body: Left(Assign) "x:=e" or
/   Right(expr) "e". Labelled with id 0, as in Scala.
.aqc.dot.udfCommand:{[c]
  if[`Right = c`node; :.aqc.dot.label[c`value; 0]];
  a:c`value;                                    / Assign(n, e)
  (.aqc.dot.str a`n),":=",.aqc.dot.label[a`e; 0]};

/ udf[u; id]
/   A function: node "f(x,y)", an edge, and one node with every command
/   of the body, joined with ";".
.aqc.dot.udf:{[u;id]
  name:(.aqc.dot.str u`n),"(",(.aqc.dot.join[","; u`args]),")";
  cs:u`cs;
  commands:();
  k:0;
  while[k < count cs;
    commands,:enlist .aqc.dot.udfCommand cs k;
    k+:1];
  text:.aqc.dot.node[id; name],(.aqc.dot.edge[id; id + 1]),.aqc.dot.node[id + 1; .aqc.dot.join[";"; commands]];
  (text; id + 2)};

/ create[c; id]
/   CREATE TABLE: nodes "create" and the table name, then the source: one
/   node "col:TypeInt,..." for a schema, or the query.
/   SCALA QUIRK: Scala makes an edge to the source but never prints it, so
/   the source node has no edge.
.aqc.dot.create:{[c;id]
  text:.aqc.dot.node[id; "create"],(.aqc.dot.edge[id; id + 1]),.aqc.dot.node[id + 1; .aqc.dot.str c`n];
  srcId:id + 2;
  source:c`source;
  if[`Right = source`node;
    r:.aqc.dot.query[source`value; srcId];
    :(text,r 0; r 1)];
  / Left(schema): a list of Tuple(column name, type)
  schema:source`value;
  colTexts:();
  k:0;
  while[k < count schema;
    s:schema k;
    colTexts,:enlist (.aqc.dot.str s`_1),":",string s`_2;   / "a:TypeInt"
    k+:1];
  (text,.aqc.dot.node[srcId; .aqc.dot.join[","; colTexts]]; srcId + 1)};

/ insertStmt[x; id]
/   INSERT INTO: nodes "insert", the table name and the column list, then
/   the source: one node "(v1,v2)" for VALUES, or the query.
.aqc.dot.insertStmt:{[x;id]
  text:.aqc.dot.node[id; "insert"];
  text,:.aqc.dot.node[id + 1; .aqc.dot.str x`n],.aqc.dot.edge[id; id + 1];
  text,:.aqc.dot.node[id + 2; .aqc.dot.join[","; x`modifier]],.aqc.dot.edge[id; id + 2];
  text,:.aqc.dot.edge[id; id + 3];
  src:x`src;
  if[`Right = src`node;
    r:.aqc.dot.query[src`value; id + 3];
    :(text,r 0; r 1)];
  / Left(values): labelled with the source node's id
  valuesText:"(",(.aqc.dot.join[","; .aqc.dot.labels[src`value; id + 3]]),")";
  (text,.aqc.dot.node[id + 3; valuesText]; id + 4)};

/ topLevel[x; id]
/   PUBLIC. (DOT lines; next free id) for one top-level statement.
.aqc.dot.topLevel:{[x;id]
  n:.aqc.nodes.name x;
  if[n = `Query; :.aqc.dot.query[x; id]];
  / the first 100 characters of the q code (SCALA QUIRK: newlines too)
  if[n = `VerbatimCode;
    c:.aqc.dot.str x`c;
    :(.aqc.dot.node[id; (100 & count c)#c]; id + 1)];
  if[n = `Load;
    lbl:"load ",(.aqc.dot.str x`file)," into ",(.aqc.dot.str x`t)," with ",(.aqc.dot.str x`sep)," sep";
    :(.aqc.dot.node[id; lbl]; id + 1)];
  if[n = `Save;
    lbl:"save query to ",(.aqc.dot.str x`file)," with ",(.aqc.dot.str x`sep)," sep";
    :(.aqc.dot.node[id; lbl]; id + 1)];
  if[n = `UDF; :.aqc.dot.udf[x; id]];
  if[n = `Update; :(.aqc.dot.node[id; "update on ",.aqc.dot.str x`t]; id + 1)];
  if[n = `Delete; :(.aqc.dot.node[id; "delete on ",.aqc.dot.str x`t]; id + 1)];
  if[n = `Create; :.aqc.dot.create[x; id]];
  if[n = `Insert; :.aqc.dot.insertStmt[x; id]];
  if[n = `Trigger;
    :(.aqc.dot.node[id; "trigger ",(.aqc.dot.str x`name)," on ",.aqc.dot.str x`table]; id + 1)];
  if[n = `DropTrigger; :(.aqc.dot.node[id; "drop trigger ",.aqc.dot.str x`name]; id + 1)];
  '"dot: not a statement: ",string n};


/ ---------------------------------------------------------------------------
/ The whole graph (Scala: Dot.toGraph)
/ ---------------------------------------------------------------------------

/ toGraph[prog]
/   PUBLIC. The DOT text for a parsed program (a list of statements):
/     digraph G {
/     0 [label="AQuery Entry"];
/     0 -> 1;
/     <the first statement, numbered from 1>
/     0 -> <next free id>;
/     <the second statement>
/     ...
/     }
.aqc.dot.toGraph:{[prog]
  text:"digraph G {\n",.aqc.dot.node[0; "AQuery Entry"];
  nextId:1;
  k:0;
  while[k < count prog;
    r:.aqc.dot.topLevel[prog k; nextId];
    text,:(.aqc.dot.edge[0; nextId]),r 0;
    nextId:r 1;
    k+:1];
  text,"}\n"};

/ graphFile[path]
/   PUBLIC. What `aquery.q -p path` prints, as lines: the graph of the
/   program in the file, or (if it does not parse) one line
/   "FAILURE<TAB>line:col<TAB>message" like -parse.
/   Like the jar, the file's line breaks are normalised first
/   (.aqc.util.normalizeLines), which matters for <q> ... </q> code.
.aqc.dot.graphFile:{[path]
  text:.aqc.util.normalizeLines .aqc.util.readFile path;
  r:.aqc.parse.parseRule[.aqc.parse.program; text];
  if[not r`ok;
    :enlist "FAILURE\t",(string r`line),":",(string r`col),"\t",.aqc.ast.escape r`msg];
  .aqc.dot.lines .aqc.dot.toGraph r`node};
