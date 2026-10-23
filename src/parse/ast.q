/ ast.q - parse-tree nodes: how they are built and how they are printed.

/ Ported from the case classes in aquery-master/src/main/scala/edu/nyu/aquery/ast/
/ (expr.scala, query.scala, ...). Only what the parser needs is here: the
/ AST features (transforms, the -p graph output, analysis helpers) are v3.


/ HOW A NODE LOOKS
/ A node is a dictionary. Its first key, `node, holds the Scala class name;
/ the next keys are the Scala fields, in Scala's order; the last key, `pos,
/ is where the node starts in the source:
/     1 + x   is
/     `node`op`l`r`pos!(`BinExpr; `Plus; <IntLit 1>; <Id x>; 1 1)
/     <Id x>  is  `node`v`pos!(`Id; "x"; 1 5)
/ pos is (line; column), or an empty list while the node has none. Scala
/ gives only some nodes a position (see .aqc.parse.positioned); the golden
/ files show which.
/ Scala strings are q strings ("x"), Scala Longs are longs, Doubles are
/ floats, Booleans are booleans.
/ Scala objects with no fields (Plus, Neg, Asc, RowId, WildCard, Even, None,
/ ...) are plain symbols: `Plus.
/ Scala's containers:
/   List     a q list of the items ("List(1, 2)" -> (item1; item2))
/   Option   the symbol `None, or a node `node`value!(`Some; x)
/   Either   a node `node`value!(`Left; x) or `node`value!(`Right; x)
/   Tuple    a node `node`_1`_2!(`Tuple; a; b)   (no position)

/ A Q TRAP: q turns a list of dictionaries that all have the same keys into
/ a table (each dictionary becomes a row). A list of two Id nodes may come
/ back as a table with columns node, v, pos. Both a list and a table give
/ item k with x k and their length with count x, so this code reads lists
/ of nodes only that way, and builds them only with .aqc.ast.append.


/ ---------------------------------------------------------------------------
/ Building nodes
/ ---------------------------------------------------------------------------

/ node[name; fields; values]
/   A node with no position yet.
/     node[`Id; enlist `v; enlist "x"]   is   `node`v`pos!(`Id;"x";`long$())
/   name:    symbol, the Scala class name
/   fields:  symbols, the Scala field names in Scala's order
/   values:  list, one value per field (may be a table, see "A Q TRAP")
.aqc.ast.node:{[name;fields;values]
  n:.aqc.ast.container[name;fields;values];
  n[`pos]:`long$();               / a new key goes at the end: pos is last
  n};

/ container[name; fields; values]
/   Like node, but with no `pos key: Some, Left, Right, Tuple, Every.
/   Scala never gives these a position.
/   The values are copied in one at a time (values k is item k of a list
/   or row k of a table), so it works whatever shape q gave values.
.aqc.ast.container:{[name;fields;values]
  n:(`node,fields)!(1 + count fields)#enlist (::);   / (::) is q's "nothing"
  n[`node]:name;
  k:0;
  while[k < count fields;
    n[fields k]:values k;
    k+:1];
  n};

/ append[items; x]
/   A new list: the items of items, then x.
/     append[(); <Id x>]   is   a 1-item list holding <Id x>
/   It makes count[items]+1 empty slots and fills them one by one, which
/   works whether items is a list or a table (see "A Q TRAP"). Joining
/   with items,enlist x would not: enlist of a dictionary is a 1-row table.
/   Copying makes building a list of n items cost about n*n/2 steps; the
/   lists in a parse tree are short (arguments, columns, statements), so
/   the simpler code was preferred.
.aqc.ast.append:{[items;x]
  n:count items;
  out:(n + 1)#enlist (::);
  k:0;
  while[k < n;
    out[k]:items k;
    k+:1];
  out[n]:x;
  out};

/ concat[xs; ys]
/   A new list: the items of xs, then the items of ys (Scala: xs ++ ys).
/   A loop, not append/[xs; ys]: ys can be a table that q made from a list
/   of nodes, and L does not support over on a table ('nyi).
.aqc.ast.concat:{[xs;ys]
  out:xs;
  k:0;
  while[k < count ys;
    out:.aqc.ast.append[out;ys k];
    k+:1];
  out};

/ isList[x]
/   Is x a list of parse-tree values (a general list, or a table that q
/   made from one)? Strings are values, not lists.
.aqc.ast.isList:{[x] (type x) in 0 11 98h};   / 11h: a list of symbols only, e.g. COUNT(*)'s List(WildCard)


/ The node types the expression rules build. One function per Scala case
/ class, named after it; the arguments are the Scala fields in order.

.aqc.ast.id:{[v] .aqc.ast.node[`Id; enlist `v; enlist v]};
.aqc.ast.binExpr:{[op;l;r] .aqc.ast.node[`BinExpr; `op`l`r; (op;l;r)]};
.aqc.ast.unExpr:{[op;v] .aqc.ast.node[`UnExpr; `op`v; (op;v)]};
.aqc.ast.funCall:{[f;args] .aqc.ast.node[`FunCall; `f`args; (f;args)]};
.aqc.ast.arrayIndex:{[e;ix] .aqc.ast.node[`ArrayIndex; `e`ix; (e;ix)]};
.aqc.ast.ifThen:{[c;t] .aqc.ast.node[`IfThen; `c`t; (c;t)]};
.aqc.ast.case:{[cond;when;e] .aqc.ast.node[`Case; `cond`when`e; (cond;when;e)]};
.aqc.ast.columnAccess:{[t;c] .aqc.ast.node[`ColumnAccess; `t`c; (t;c)]};

/ The node types the query rules build (Scala: ast/query.scala). Scala's
/ `attr` field (filled in by later analysis, always empty after parsing) is
/ left out, as in the golden files.
/ Query(local, main): WITH local queries, then the main query
.aqc.ast.query:{[local;main] .aqc.ast.node[`Query; `local`main; (local;main)]};
/ Project(t, ps): SELECT ps FROM t; ps is a list of Tuple(expr, alias)
.aqc.ast.project:{[t;ps] .aqc.ast.node[`Project; `t`ps; (t;ps)]};
/ Filter(t, fs): WHERE fs
.aqc.ast.filter:{[t;fs] .aqc.ast.node[`Filter; `t`fs; (t;fs)]};
/ GroupBy(t, gs, having): GROUP BY gs HAVING having
.aqc.ast.groupBy:{[t;gs;having] .aqc.ast.node[`GroupBy; `t`gs`having; (t;gs;having)]};
/ SortBy(t, os): ASSUMING os; os is a list of Tuple(`Asc or `Desc, expr)
.aqc.ast.sortBy:{[t;os] .aqc.ast.node[`SortBy; `t`os; (t;os)]};
/ Table(n, alias): a table name, alias is `None or Some(name)
.aqc.ast.table:{[n;alias] .aqc.ast.node[`Table; `n`alias; (n;alias)]};
/ TopApply(f, t): SHOW, EXEC_ARRAYS or DISTINCT applied to a whole query
.aqc.ast.topApply:{[f;t] .aqc.ast.node[`TopApply; `f`t; (f;t)]};
/ BottomApply(f, args): a function call used as a table, FROM f(1)
.aqc.ast.bottomApply:{[f;args] .aqc.ast.node[`BottomApply; `f`args; (f;args)]};
/ Join(jt, l, r, cond): jt is `InnerJoinUsing, `FullOuterJoinUsing or
/ `Cross; cond is the list of USING columns
.aqc.ast.join:{[jt;l;r;cond] .aqc.ast.node[`Join; `jt`l`r`cond; (jt;l;r;cond)]};

/ The node types the statement rules build (Scala: ast/data.scala,
/ query.scala, trigger.scala, udf.scala, VerbatimCode.scala). A few names
/ get "Stmt" added, because insert, update, delete, load and save are q
/ built-ins.
/ Create(n, source): source is Left(schema) or Right(query)
.aqc.ast.create:{[n;source] .aqc.ast.node[`Create; `n`source; (n;source)]};
/ Insert(n, order, modifier, src): src is Left(values) or Right(query)
.aqc.ast.insertStmt:{[n;order;modifier;src] .aqc.ast.node[`Insert; `n`order`modifier`src; (n;order;modifier;src)]};
/ Update(t, assigns, order, where, groupby, having)
.aqc.ast.updateStmt:{[t;assigns;order;conds;groupby;having]
  .aqc.ast.node[`Update; `t`assigns`order`where`groupby`having; (t;assigns;order;conds;groupby;having)]};
/ Delete(t, del, order, groupby, having): del is Left(columns) or Right(where)
.aqc.ast.deleteStmt:{[t;del;order;groupby;having]
  .aqc.ast.node[`Delete; `t`del`order`groupby`having; (t;del;order;groupby;having)]};
/ Load(file, t, sep) and Save(file, query, sep)
.aqc.ast.loadStmt:{[file;t;sep] .aqc.ast.node[`Load; `file`t`sep; (file;t;sep)]};
.aqc.ast.saveStmt:{[file;query;sep] .aqc.ast.node[`Save; `file`query`sep; (file;query;sep)]};
/ UDF(n, args, cs): cs is a list of Left(Assign) or Right(expr)
.aqc.ast.udf:{[n;args;cs] .aqc.ast.node[`UDF; `n`args`cs; (n;args;cs)]};
/ Assign(n, e): n := e inside a function. Scala never positions it.
.aqc.ast.assign:{[n;e] .aqc.ast.node[`Assign; `n`e; (n;e)]};
/ VerbatimCode(c): q code between <q> and </q>
.aqc.ast.verbatimCode:{[c] .aqc.ast.node[`VerbatimCode; enlist `c; enlist c]};
/ Trigger(name, time, event, table, refs, body)
.aqc.ast.trigger:{[name;time;event;tbl;refs;body]
  .aqc.ast.node[`Trigger; `name`time`event`table`refs`body; (name;time;event;tbl;refs;body)]};
/ TriggerRef(kind, alias): not a Scala AST class, so it has no position
.aqc.ast.triggerRef:{[kind;alias] .aqc.ast.container[`TriggerRef; `kind`alias; (kind;alias)]};
/ DropTrigger(name)
.aqc.ast.dropTrigger:{[name] .aqc.ast.node[`DropTrigger; enlist `name; enlist name]};

/ TableColumnValue(t, c): column c of WITH local query t, written t("c").
/ Only made by the string-constant rewrite (rewrite.q).
.aqc.ast.tableColumnValue:{[t;c] .aqc.ast.node[`TableColumnValue; `t`c; (t;c)]};

/ Literals: name is `IntLit, `FloatLit, `StringLit, `DateLit,
/ `TimestampLit or `BooleanLit.
.aqc.ast.lit:{[name;v] .aqc.ast.node[name; enlist `v; enlist v]};

/ Every(n), the index operator x[every n]. Scala gives it no position.
.aqc.ast.every:{[n] .aqc.ast.container[`Every; enlist `v; enlist n]};

/ Scala's containers (see the top of this file).
.aqc.ast.some:{[x] .aqc.ast.container[`Some; enlist `value; enlist x]};
.aqc.ast.left:{[x] .aqc.ast.container[`Left; enlist `value; enlist x]};
.aqc.ast.right:{[x] .aqc.ast.container[`Right; enlist `value; enlist x]};
.aqc.ast.tuple:{[parts]
  names:`$"_",'string 1 + til count parts;     / `_1`_2...
  .aqc.ast.container[`Tuple; names; parts]};

/ isNode[x]
/   Is x a node or container (a dictionary with a `node key)?
.aqc.ast.isNode:{[x] $[99h = type x; `node in key x; 0b]};   / $[...] so key never sees a non-dictionary

/ fields[x]
/   The Scala field names of node x: every key but `node and `pos.
.aqc.ast.fields:{[x] (key x) except `node`pos};


/ ---------------------------------------------------------------------------
/ Printing numbers the way Java does
/ ---------------------------------------------------------------------------

/ shortestDecimal[x]
/   x (positive) in plain decimal notation with the fewest digits after the
/   point that still give back exactly x, and at least one: what Java's
/   Double.toString prints for numbers from 0.001 up to 10 million.
/     shortestDecimal 1.5     is "1.5"
/     shortestDecimal 100f    is "100.0"
/   It tries 1, 2, ... 17 significant digits and keeps the first text that
/   "F"$ reads back as exactly x (17 digits always do).
/   .Q.f is not used: for more than about 13 digits it gives up and prints
/   x with only 7 digits ("3.141593"), in L as in q.
.aqc.ast.shortestDecimal:{[x]
  exponent:floor 10 xlog x;       / x is about 10^exponent: 1234.5 -> 3
  digits:1;
  / digits significant digits = (digits - 1) - exponent digits after the
  / point (the brackets matter: q reads a - b - c as a - (b - c))
  txt:.aqc.ast.fixedPoint[x;(digits - 1) - exponent];
  while[(digits < 17) and not .aqc.ast.sameFloat[x;"F"$txt];
    digits+:1;
    txt:.aqc.ast.fixedPoint[x;(digits - 1) - exponent]];
  txt};

/ sameFloat[a; b]
/   Are floats a and b exactly equal? q's = and ~ are "tolerant" for floats
/   (3.14159265359 = 3.14159265358979 is 1b), but a comparison with 0 is
/   exact, and a - b is 0 only when a and b are the same number.
.aqc.ast.sameFloat:{[a;b] 0 = a - b};

/ fixedPoint[x; scale]
/   x (positive) rounded to scale digits after the point, written out in
/   plain decimal with at least one digit after the point. A scale of 0 or
/   less rounds to a whole number (-2: to hundreds).
/     fixedPoint[3.14159; 2]   is "3.14"
/     fixedPoint[0.001; 3]     is "0.001"
/     fixedPoint[123.0; -2]    is "100.0"
.aqc.ast.fixedPoint:{[x;scale]
  / the kept digits as one whole number: x * 10^scale, rounded
  / (dividing by 10^-scale instead of multiplying by 10^scale when scale is
  / negative, because 10 xexp -2 is not exactly 0.01)
  scaled:$[scale >= 0; x * 10 xexp scale; x % 10 xexp neg scale];
  ds:string `long$scaled;          / `long$ rounds to the nearest whole number
  / no digits after the point: add the zeros the rounding removed, then ".0"
  if[scale <= 0; :ds,((neg scale)#"0"),".0"];
  / pad with leading zeros so at least one digit is left before the point
  / (0 | ... because -3#"0" is still "000": a negative count takes from
  / the end, and # repeats a list that is too short)
  ds:((0 | scale + 1 - count ds)#"0"),ds;
  / the point goes before the last scale digits
  whole:((count ds) - scale)#ds;   / all but the last scale digits
  fraction:(neg scale)#ds;         / the last scale digits
  whole,".",fraction};

/ javaDouble[x]
/   x as Java's Double.toString writes it (Scala prints doubles this way, so
/   the golden files do too). Below 0.001 and from 10 million up Java uses
/   scientific notation: "1.0E7", "1.0E-4".
/     javaDouble -1.5   is "-1.5"
/     javaDouble 1e7    is "1.0E7"
.aqc.ast.javaDouble:{[x]
  if[x < 0; :"-",.aqc.ast.javaDouble neg x];
  if[x = 0; :"0.0"];
  if[(x >= 0.001) and x < 1e7; :.aqc.ast.shortestDecimal x];
  / scientific: x = mantissa * 10^exponent, with 1 <= mantissa < 10
  exponent:floor 10 xlog x;
  mantissa:x % 10 xexp exponent;
  / xlog can be a hair off for exact powers of 10; correct for that
  if[mantissa >= 10; mantissa%:10; exponent+:1];
  if[mantissa < 1; mantissa*:10; exponent-:1];
  (.aqc.ast.shortestDecimal mantissa),"E",string exponent};


/ ---------------------------------------------------------------------------
/ show: one line, like Scala's toString
/ ---------------------------------------------------------------------------

/ isScalar[x]
/   Is x a symbol, long, float or boolean atom: a value printed as one word?
.aqc.ast.isScalar:{[x] (type x) in -11 -7 -9 -1h};

/ scalarText[x]
/   A scalar (see isScalar) as Scala prints it; show and format share it.
/     scalarText `Plus   is "Plus"
/     scalarText 2.5     is "2.5"      (Java's double format, see javaDouble)
/     scalarText 1b      is "true"
.aqc.ast.scalarText:{[x]
  $[-9h = type x; .aqc.ast.javaDouble x;
    -1h = type x; $[x; "true"; "false"];
    string x]};                   / a symbol or a long

/ show[x]
/   PUBLIC. A node (or any value inside one) on one line, exactly as Scala
/   prints the same case class. Positions are left out. The parser unit
/   tests compare against these strings, taken from the real Scala parser
/   with tools/RuleDump.java.
/     show <the tree for "1 + x">   is   "BinExpr(Plus,IntLit(1),Id(x))"
.aqc.ast.show:{[x]
  t:type x;
  if[10h = t; :x];                              / a string prints bare: Id(x)
  / a single character "a" is a char atom, not a string, in q (and a
  / table column of 1-character strings can give one back): print it the
  / same way
  if[-10h = t; :enlist x];
  if[.aqc.ast.isScalar x; :.aqc.ast.scalarText x];   / Plus, 1, 2.5, true
  / a list: List(a, b)   (Scala puts ", " between list items)
  if[.aqc.ast.isList x; :"List(",(.aqc.ast.joinShown[", ";x]),")"];
  / a node: Name(field1,field2,...)   (only "," between fields)
  / a Tuple has no name: (a,b)
  name:$[`Tuple = x`node; ""; string x`node];
  name,"(",(.aqc.ast.joinShown[",";x .aqc.ast.fields x]),")"};

/ joinShown[separator; xs]
/   show each item of xs, with separator between them. "" if xs is empty.
/     joinShown[", "; (<Id a>; <Id b>)]   is   "Id(a), Id(b)"
/   sv joins a list of strings with separator between them. Its result for
/   an empty list is not a string, hence the first case.
.aqc.ast.joinShown:{[separator;xs]
  $[0 = count xs; ""; separator sv .aqc.ast.show each xs]};


/ ---------------------------------------------------------------------------
/ format: the indented tree of the golden files
/ ---------------------------------------------------------------------------

/ escape[txt]
/   Make a string printable on one line inside double quotes (the same
/   rules as tools/AstDump.java): \ " tab newline return become
/   \\ \" \t \n \r.
.aqc.ast.escape:{[txt]
  txt:ssr[txt;"\\";"\\\\"];       / first, so the backslashes added below stay single
  txt:ssr[txt;"\"";"\\\""];
  txt:ssr[txt;"\t";"\\t"];
  txt:ssr[txt;"\n";"\\n"];
  ssr[txt;"\r";"\\r"]};

/ posText[x]
/   " @line:col" for a node with a position, "" otherwise.
.aqc.ast.posText:{[x]
  if[not `pos in key x; :""];
  if[0 = count x`pos; :""];
  " @",(string x[`pos] 0),":",string x[`pos] 1};

/ format[depth; label; x]
/   PUBLIC. x as lines of the golden-file format (tests/parser/README.md):
/   the first line is 2*depth spaces, then label, then x itself; the parts
/   of x follow, one level deeper.
/     format[0; ""; <the tree for "1 + x">]   is
/       ("BinExpr @1:1";"  op: Plus";"  l: IntLit @1:1";"    v: 1";
/        "  r: Id @1:5";"    v: \"x\"")
/   returns: list of strings
.aqc.ast.format:{[depth;label;x]
  start:(2 * depth)#" ";          / 2*depth spaces
  start,:label;
  t:type x;
  if[-10h = t; x:enlist x; t:10h];              / a char atom "a": treat as a string (see show)
  if[10h = t; :enlist start,"\"",(.aqc.ast.escape x),"\""];
  if[.aqc.ast.isScalar x; :enlist start,.aqc.ast.scalarText x];
  if[.aqc.ast.isList x;
    if[0 = count x; :enlist start,"[]"];
    / "List", then each item one level deeper, labelled "- "
    / (format[depth + 1; "- "] is format with x left out: a function of
    / one item; raze joins the items' lists of lines into one list)
    :(enlist start,"List"),raze .aqc.ast.format[depth + 1; "- "] each x];
  / a node: its name and position, then each field one level deeper
  header:start,(string x`node),.aqc.ast.posText x;
  (enlist header),raze .aqc.ast.formatField[depth + 1; x] each .aqc.ast.fields x};

/ formatField[depth; x; name]
/   Field name of node x as format lines, labelled "name: ".
/     formatField[1; <Id x>; `v]   is   enlist "  v: \"x\""
.aqc.ast.formatField:{[depth;x;name]
  .aqc.ast.format[depth; (string name),": "; x name]};
