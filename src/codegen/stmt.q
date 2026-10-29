/ stmt.q - q code for the statements that are not queries: CREATE, INSERT,
/ UPDATE, DELETE, LOAD, SAVE and FUNCTION.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/codegen/
/ KdbGenerator.scala: genCreate, genSchema, getTypeCode, genInsert,
/ genUpdate, genDelete, genBooleanVector, genDataIO, getFileHandle,
/ toKdbSymList, genUDF and genAssign. Triggers come in milestone 4.

/ WHAT THE CODE LOOKS LIKE
/ Most statements run a query inside a q lambda that is called at once,
/ {...}[], and hand the result to a base.q function:
/     CREATE TABLE u SELECT a FROM t
/   becomes
/     .aq.show `u set {
/      .aq.initQueryState[];
/      aq__t0:.aq.initTable[t;"t";0b];
/      aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];
/      aq__t0
/      }[];
/ UPDATE and DELETE first copy the table into aq__t0 (sorted when there is
/ an ASSUMING) and then call .aq.update or .aq.deleteRows on it.


/ ---------------------------------------------------------------------------
/ Small helpers
/ ---------------------------------------------------------------------------

/ symList[names]
/   Names as a q symbol list (Scala: toKdbSymList). One name gets enlist,
/   so that it is still a list.
/     symList ("a";"b")      is "`a`b"
/     symList enlist "a"     is "enlist `a"
/     symList ()             is "()"
.aqc.gen.symList:{[names]
  if[0 = count names; :"()"];
  syms:raze .aqc.gen.sym each names;
  $[1 = count names; "enlist ",syms; syms]};

/ fileHandle[f]
/   A q file handle for the path f (Scala: getFileHandle).
/     fileHandle "a.csv"   is "hsym `$\"a.csv\""
.aqc.gen.fileHandle:{[f] "hsym `$\"",(.aqc.gen.str f),"\""};

/ inLambda[code]
/   code inside a q lambda that is called at once, the way CREATE and
/   SAVE wrap their query: "{\n",code,"\n }[]".
.aqc.gen.inLambda:{[code] "{\n",code,"\n }[]"};

/ plainTable[n; os]
/   The plan for FROM n, or for FROM n ASSUMING os when os is not empty
/   (Scala: Table(n), or SortBy(Table(n), os)).
.aqc.gen.plainTable:{[n;os]
  t:.aqc.ast.table[n; `None];
  $[0 = count os; t; .aqc.ast.sortBy[t; os]]};

/ ignoreResult[t]
/   The finish for planCode when the statement uses the result table
/   later: nothing. The plan's code then ends with "\n " (a line with
/   one space), as in Scala.
.aqc.gen.ignoreResult:{[t] ""};


/ ---------------------------------------------------------------------------
/ CREATE TABLE (Scala: genCreate, genSchema, getTypeCode)
/ ---------------------------------------------------------------------------

/ The q type letter of each AQuery column type. INT is a q long ("j"),
/ the default integer in kdb+ 3.x.
.aqc.gen.typeCodes:`TypeInt`TypeFloat`TypeDate`TypeTimestamp`TypeString`TypeBoolean!
  ("j";"f";"d";"p";"s";"b");

/ schema[cols]
/   An empty q table with the given columns (Scala: genSchema). cols is a
/   list of Tuple(name, type).
/     CREATE TABLE t (a INT, b FLOAT)   gives   "([]a:\"j\"$();b:\"f\"$())"
.aqc.gen.schema:{[colDefs]
  parts:();
  k:0;
  while[k < count colDefs;
    c:colDefs k;
    parts,:enlist (.aqc.gen.str c`_1),":\"",(.aqc.gen.typeCodes c`_2),"\"$()";
    k+:1];
  "([]",(.aqc.gen.join[";"; parts]),")"};

/ createStmt[c]
/   CREATE TABLE n (schema) or CREATE TABLE n QUERY: set the global n.
.aqc.gen.createStmt:{[c]
  name:.aqc.gen.sym c`n;
  source:c`source;                            / Left(schema) or Right(query)
  if[`Left ~ source`node; :".aq.show ",name," set ",(.aqc.gen.schema source`value),";"];
  ".aq.show ",name," set ",(.aqc.gen.inLambda .aqc.gen.query source`value),";"};


/ ---------------------------------------------------------------------------
/ INSERT (Scala: genInsert)
/ ---------------------------------------------------------------------------

/ insertStmt[i]
/   INSERT INTO n [ASSUMING os] [(columns)] VALUES(...) or QUERY:
/     .aq.insert[`n; TABLE; COLUMNS; DATA]
/   TABLE is n, or the code that sorts n when there is an ASSUMING.
/   DATA is the values as a list, or the query's code in a lambda.
/   SCALA QUIRK: these lambdas are written "\n {\n code \n }[]" (sorted
/   table, with a space before the last "\n") and "\n {\n code\n }[]".
/   No ";" at the end, unlike the other statements.
.aqc.gen.insertStmt:{[i]
  n:.aqc.gen.str i`n;
  sorted:n;
  if[0 < count i`order;
    sortPlan:.aqc.gen.plainTable[n; i`order];
    sorted:"\n {\n ",(.aqc.gen.planCode[sortPlan; {[t] t}; 1b])," \n }[]"];
  src:i`src;                                  / Left(values) or Right(query)
  data:$[`Left ~ src`node;
    "eval ",.aqc.gen.addEnlist .aqc.gen.exprList[src`value; 0b];
    "\n {\n ",(.aqc.gen.query src`value),"\n }[]"];
  modifier:.aqc.gen.symList i`modifier;
  ".aq.insert[",(.aqc.gen.sym n),";",sorted,";",modifier,";",data,"]"};


/ ---------------------------------------------------------------------------
/ UPDATE and DELETE (Scala: genUpdate, genDelete, genBooleanVector)
/ ---------------------------------------------------------------------------

/ The name of the boolean vector that marks the rows a HAVING keeps.
.aqc.gen.ixName:"aq__ix";

/ rowsVector[sortedT; conds; groups; having]
/   For UPDATE/DELETE with HAVING (Scala: genBooleanVector): code that
/   sets aq__ix to a boolean vector, one item per row of table sortedT,
/   true where the row is in a group that HAVING keeps. It runs the query
/     SELECT *, ROWID AS aq__ix FROM sortedT WHERE conds
/       GROUP BY groups HAVING having
/   and sets aq__ix to 1b at the row numbers in its aq__ix column.
/   The code is generated with plan (not planCode), so the state of the
/   statement around it (its aq__tN numbers) is kept; grouped is turned
/   off again after.
.aqc.gen.rowsVector:{[sortedT;conds;groups;having]
  vec:.aqc.gen.ixName;
  items:.aqc.ast.append[.aqc.ast.append[(); .aqc.ast.tuple (`WildCard; `None)];
    .aqc.ast.tuple (`RowId; .aqc.ast.some vec)];
  q:.aqc.ast.project[.aqc.ast.table[sortedT; `None]; items];
  q:.aqc.ast.filter[q; conds];
  q:.aqc.ast.groupBy[q; .aqc.gen.noAlias groups; having];
  indexQuery:.aqc.gen.plan q;
  indexTable:.aqc.gen.get `currTable;
  .aqc.gen.set[`grouped; 0b];
  assign:" ",vec,":@[(count ",sortedT,")#0b;(ungroup 0!",indexTable,")",(.aqc.gen.sym vec),";:;1b]";
  .aqc.gen.initQueryState,"\n",indexQuery,"\n ",assign,";"};

/ updateStmt[u]
/   UPDATE t SET c = e, ... [ASSUMING os] [WHERE conds] [GROUP BY gs
/   [HAVING having]]:
/     {
/      (copy t to aq__t0, sorted by os)
/      .aq.update[`t; aq__t0; WHERE; GROUPS (dictionary or 0b); SETS (dictionary)]
/      }[];
/   With HAVING, WHERE is enlist aq__ix, the rows rowsVector found.
.aqc.gen.updateStmt:{[u]
  groups:.aqc.gen.addColNames .aqc.gen.noAlias u`groupby;
  init:.aqc.gen.planCode[.aqc.gen.plainTable[u`t; u`order]; .aqc.gen.ignoreResult; 1b];
  sortedT:.aqc.gen.get `currTable;
  conds:.aqc.gen.exprList[u`where; 1b];
  byCode:$[0 = count groups; "0b"; .aqc.gen.exprDict[groups; .aqc.gen.colLookup]];
  / SET c = e is Tuple(c, e); exprDict wants (expression; name) pairs
  sets:();
  k:0;
  while[k < count u`assigns;
    a:(u`assigns) k;
    sets,:enlist (a`_2; .aqc.gen.str a`_1);
    k+:1];
  setCode:.aqc.gen.exprDict[sets; .aqc.gen.colLookup];
  name:.aqc.gen.sym u`t;
  if[0 = count u`having;
    :"{\n",init,"\n .aq.update[",name,";",sortedT,";",conds,";",byCode,";",setCode,"]\n }[];"];
  ix:.aqc.gen.rowsVector[sortedT; u`where; u`groupby; u`having];
  "{\n",init,"\n",ix,"\n\n .aq.update[",name,";",sortedT,";enlist ",.aqc.gen.ixName,";",byCode,";",setCode,"]\n }[];"};

/ deleteStmt[d]
/   DELETE c, ... FROM t: drop columns, with q's functional delete
/   ![t;();0b;COLUMNS], and store the result in t.
/   DELETE FROM t [ASSUMING os] [WHERE conds] [GROUP BY gs [HAVING
/   having]]: drop rows with .aq.deleteRows, like updateStmt.
/   SCALA QUIRK: GROUP BY without HAVING is ignored.
.aqc.gen.deleteStmt:{[d]
  name:.aqc.gen.sym d`t;
  init:.aqc.gen.planCode[.aqc.gen.plainTable[d`t; d`order]; .aqc.gen.ignoreResult; 1b];
  del:d`del;                                  / Left(columns) or Right(where)
  if[`Left ~ del`node;
    colCode:.aqc.gen.exprList[del`value; 1b];
    :".aq.show ",name," set {\n",init,"\n ![",(.aqc.gen.str d`t),";();0b;",colCode,"]\n }[];"];
  sortedT:.aqc.gen.get `currTable;
  conds:.aqc.gen.exprList[del`value; 1b];
  if[0 = count d`having;
    :"{\n",init,"\n .aq.deleteRows[",name,";",sortedT,";",conds,"]\n }[];"];
  ix:.aqc.gen.rowsVector[sortedT; del`value; d`groupby; d`having];
  "{\n",init,"\n",ix,"\n\n .aq.deleteRows[",name,";",sortedT,";enlist ",.aqc.gen.ixName,"]\n }[];"};


/ ---------------------------------------------------------------------------
/ LOAD and SAVE (Scala: genDataIO)
/ ---------------------------------------------------------------------------

/ loadStmt[l]
/   LOAD DATA INFILE "f" INTO TABLE t FIELDS TERMINATED BY "sep"
/     .aq.show .aq.load[hsym `$"f";"sep";`t];
.aqc.gen.loadStmt:{[l]
  ".aq.show .aq.load[",(.aqc.gen.fileHandle l`file),";\"",(.aqc.gen.str l`sep),"\";",(.aqc.gen.sym l`t),"];"};

/ saveStmt[s]
/   QUERY INTO OUTFILE "f" FIELDS TERMINATED BY "sep": .aq.save with the
/   file and separator fixed (a projection, the space is its empty
/   argument) applied to the query's result.
/   SCALA QUIRK: the lambda starts "{\n " (one more space than CREATE's).
.aqc.gen.saveStmt:{[s]
  query:.aqc.gen.query s`query;
  ".aq.show .aq.save[",(.aqc.gen.fileHandle s`file),";\"",(.aqc.gen.str s`sep),"\"; ] {\n ",query,"\n }[];"};


/ ---------------------------------------------------------------------------
/ FUNCTION (Scala: genUDF, genAssign)
/ ---------------------------------------------------------------------------

/ udf[u]
/   FUNCTION n(args) { body }: a q function n. Each item of the body is
/   evaluated with eval; x := e becomes a local x:eval e. The last item is
/   the function's result.
/     FUNCTION f(x) { z := x + 1; z * 2 }   becomes
/     f:{[x]
/       z:eval (+; .aq.funEnlist x; 1);
/      eval (*; .aq.funEnlist z; 2)
/      };
/   Inside the body names are variables (nameAsVar, inUDF), so they are
/   wrapped in .aq.funEnlist rather than looked up as columns.
.aqc.gen.udf:{[u]
  .aqc.gen.set[`nameAsVar; 1b];
  .aqc.gen.set[`inUDF; 1b];
  parts:();
  k:0;
  while[k < count u`cs;
    c:(u`cs) k;                               / Left(Assign) or Right(expr)
    v:c`value;
    parts,:enlist $[`Left ~ c`node;
      " ",(.aqc.gen.str v`n),":eval ",.aqc.gen.expr v`e;
      "eval ",.aqc.gen.expr v];
    k+:1];
  .aqc.gen.set[`nameAsVar; 0b];
  .aqc.gen.set[`inUDF; 0b];
  argNames:.aqc.gen.join[";"; .aqc.gen.str each u`args];
  (.aqc.gen.str u`n),":{[",argNames,"]\n ",(.aqc.gen.join[";\n "; parts]),"\n };"};
