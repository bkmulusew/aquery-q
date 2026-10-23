/ parser.q - the AQuery parser: token table -> parse tree.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala
/ (the grammar rules, from `def program` down). Needs util.q, keywords.q,
/ jdate.q, lex.q and ast.q to be loaded first.
/ Version 2: the expression rules (milestone 2), the query rules
/ (milestone 3) and the statement rules and whole program (milestone 4).
/ The string-constant rewrite that ends `program` is in rewrite.q.

/ HOW IT WORKS
/ Scala builds the parser from small "combinators": p ~ q (p then q),
/ p | q (try p; if it fails, go back and try q), rep(p) (p any number of
/ times). Here every grammar rule is one q function, with the Scala rule's
/ name, that looks at the tokens from index i on:
/     rule[i]  ->  `ok`node`next!(1b; tree built; index of the next token)
/              or  `ok`msg`at!(0b; error message; index where it gave up)
/ (the same ok/fail convention as the lexer's rules). Going back after a
/ failure is free: the caller simply tries something else at the same i.

/ The tokens being parsed live in the global .aqc.parse.toks (the table
/ from .aqc.lex.tokens), so the rules only need the index i.

/ Error position: like Scala, the parser remembers the failure that got
/ furthest into the input (.aqc.parse.furthest). If the whole parse fails,
/ that is the error reported. Scala's messages are often misleading (they
/ name the last thing it tried), so only the position is tested.


/ ---------------------------------------------------------------------------
/ Results and the furthest failure
/ ---------------------------------------------------------------------------

/ ok[node; next]  a rule matched; the next token to look at is next
/ (nxt, not next: next is a q built-in and L refuses it as a name)
.aqc.parse.ok:{[node;nxt] `ok`node`next!(1b;node;nxt)};

/ fail[msg; at]
/   A rule gave up at token at. Also remembered as the furthest failure if
/   it got at least as far as the one so far (Scala: lastNoSuccess).
.aqc.parse.fail:{[msg;at]
  r:`ok`msg`at!(0b;msg;at);
  if[at >= .aqc.parse.furthest`at; .aqc.parse.furthest:r];
  r};

/ firstOf[rules; i]
/   Scala's p | q | ...: the result of the first rule that matches at i.
/   If none does, the failure that got furthest (on a tie, the later rule).
.aqc.parse.firstOf:{[rules;i]
  best:`ok`msg`at!(0b;"";-1);
  k:0;
  while[k < count rules;
    r:rules[k] i;
    if[r`ok; :r];
    if[(r`at) >= best`at; best:r];
    k+:1];
  best};

/ positioned[i; r]
/   Scala's positioned(...): if rule result r is ok and its node has no
/   position yet, give it the position of token i (where the rule started).
/   A node that already has a position keeps it; so does a symbol like
/   `RowId (Scala's shared objects print no position).
.aqc.parse.positioned:{[i;r]
  if[not r`ok; :r];
  n:r`node;
  if[not 99h = type n; :r];                     / not a node
  if[not `pos in key n; :r];                    / a container: never positioned
  if[0 < count n`pos; :r];                      / already has one
  n[`pos]:.aqc.parse.posAt i;
  r[`node]:n;
  r};


/ ---------------------------------------------------------------------------
/ Looking at tokens
/ ---------------------------------------------------------------------------

/ token[i]
/   Row i of the token table (kind, text, line, col). Indexes past the end
/   give the last row, which is always EOF.
.aqc.parse.token:{[i] .aqc.parse.toks ((count .aqc.parse.toks) - 1) & i};

/ posAt[i]  (line; col) of token i
.aqc.parse.posAt:{[i] t:.aqc.parse.token i; (t`line;t`col)};

/ atEnd[i]  is token i the final EOF row (nothing left to parse)?
.aqc.parse.atEnd:{[i] i >= (count .aqc.parse.toks) - 1};

/ describe[t]
/   Token row t as Scala names it in error messages.
/     a keyword or delimiter  `SELECT'      an identifier  identifier x
/     a string                "abc"         a number       42
.aqc.parse.describe:{[t]
  k:t`kind;
  s:t`text;
  $[k = `Keyword; "`",s,"'";
    k = `Identifier; "identifier ",s;
    k = `StringLit; "\"",s,"\"";
    k = `ErrorToken; "ErrorToken(",(11_s),")";   / 11_ drops "*** error: "
    k = `EOF; "end of input";
    s]};

/ spellings[word]
/   The exact spellings that make keyword word (Scala: Keyword.canonical):
/   upper case, plus lower case unless it is one of the alwaysUpper words.
/     spellings `SELECT   is ("SELECT";"select")
/     spellings `INT      is enlist "INT"
.aqc.parse.spellings:{[word]
  capitals:string word;
  $[word in .aqc.kw.alwaysUpper; enlist capitals; (capitals;lower capitals)]};

/ accept[i; spellings]
/   Scala's keyword("..."): token i must be a Keyword token (a keyword or a
/   delimiter) spelled exactly like one of spellings (a list of strings).
/   The node is the token's text.
.aqc.parse.accept:{[i;spellings]
  t:.aqc.parse.token i;
  txt:(),t`text;                  / (), makes a 1-character text a string
  if[(`Keyword = t`kind) and any spellings ~\: txt; :.aqc.parse.ok[txt;i + 1]];
  / Scala's message quotes the expected text with `` and '' (TeX style)
  .aqc.parse.fail["``",(last spellings),"'' expected but ",(.aqc.parse.describe t)," found";i]};

/ kw[i; word]      keyword word (a symbol, e.g. `SELECT) at token i
.aqc.parse.kw:{[i;word] .aqc.parse.accept[i;.aqc.parse.spellings word]};

/ delim[i; text]   the delimiter text (e.g. "(" or "<=") at token i
.aqc.parse.delim:{[i;text] .aqc.parse.accept[i;enlist (),text]};   / (), makes "(" a string

/ tokenOfKind[i; kind; what]
/   Token i must be of this kind; the node is its text.
/   what names it in the error message ("identifier", ...).
.aqc.parse.tokenOfKind:{[i;kind;what]
  t:.aqc.parse.token i;
  if[kind = t`kind; :.aqc.parse.ok[t`text;i + 1]];
  .aqc.parse.fail[what," expected";i]};

/ Scala's ident, numericLit and stringLit. (Dates and timestamps are read
/ straight from the token in lit.)
.aqc.parse.ident:{[i] .aqc.parse.tokenOfKind[i;`Identifier;"identifier"]};
.aqc.parse.numericLit:{[i] .aqc.parse.tokenOfKind[i;`NumericLit;"number"]};
.aqc.parse.stringLit:{[i] .aqc.parse.tokenOfKind[i;`StringLit;"string literal"]};

/ pick[i; choices]
/   One of several keywords. choices maps each keyword to the node to give
/   for it; they are tried in order (Scala: A ^^^ a | B ^^^ b | ...).
/     pick[i; `BEFORE`AFTER!`Before`After]   on "AFTER"  gives `After
/   If none matches, the failure is the last keyword's, as in Scala.
.aqc.parse.pick:{[i;choices]
  words:key choices;
  k:0;
  while[k < count words;
    r:.aqc.parse.kw[i;words k];
    if[r`ok; :.aqc.parse.ok[choices words k;r`next]];
    k+:1];
  r};

/ between[open; rule; close; i]
/   The delimiter open, then rule, then the delimiter close; the node is
/   rule's (Scala: open ~> rule <~ close).
/     between["("; expr; ")"; i]   on "(1 + 2)"  gives the tree for 1 + 2
/   Called with i left out, between["("; expr; ")"] is itself a rule.
.aqc.parse.between:{[open;rule;close;i]
  r:.aqc.parse.delim[i;open];
  if[not r`ok; :r];
  r:rule r`next;
  if[not r`ok; :r];
  c:.aqc.parse.delim[r`next;close];
  if[not c`ok; :c];
  .aqc.parse.ok[r`node;c`next]};


/ ---------------------------------------------------------------------------
/ Expressions
/ Lowest precedence first: | & (= !=) (< <= > >=) (+ -) (* /) ^ unary base
/ ---------------------------------------------------------------------------

/ leftChain[operand; ops; i]
/   operand, then any number of (operator operand), grouped to the left:
/   a - b - c is (a - b) - c. ops maps each operator to its Scala BinOp:
/     ("+";"-")!`Plus`Minus
/   Scala writes this with a left-recursive rule (add = add + mult | mult),
/   which its "packrat" parser allows; a loop does the same job.
/   If an operator is not followed by an operand, the chain stops before
/   that operator (Scala backtracks the same way).
/   Every BinExpr built here starts at token i, so they all get i's
/   position (positioned, as in Scala).
.aqc.parse.leftChain:{[operand;ops;i]
  r:operand i;
  if[not r`ok; :r];
  while[1b;
    op:.aqc.parse.accept[r`next;key ops];
    if[not op`ok; :r];
    right:operand op`next;
    if[not right`ok; :r];
    tree:.aqc.ast.binExpr[ops op`node;r`node;right`node];
    r:.aqc.parse.positioned[i;.aqc.parse.ok[tree;right`next]]];
  r};

/ The rules are named after Scala's (expr, and, eq, ...) with "Expr"
/ added, because "and" is a q built-in and cannot be a name.

/ Scala: expr = expr "|" and | and
.aqc.parse.expr:{[i] .aqc.parse.leftChain[.aqc.parse.andExpr;(enlist enlist "|")!enlist `Lor;i]};

/ Scala: and = and "&" eq | eq
.aqc.parse.andExpr:{[i] .aqc.parse.leftChain[.aqc.parse.eqExpr;(enlist enlist "&")!enlist `Land;i]};

/ Scala: eq = eq ("=" | "!=") rel | rel
/ (The lexer also makes "<>" and "==" tokens, but no rule uses them.)
.aqc.parse.eqExpr:{[i] .aqc.parse.leftChain[.aqc.parse.relExpr;(enlist "=";"!=")!`Eq`Neq;i]};

/ Scala: rel = rel ("<=" | ">=" | "<" | ">") add | add
.aqc.parse.relExpr:{[i] .aqc.parse.leftChain[.aqc.parse.addExpr;("<=";">=";enlist "<";enlist ">")!`Le`Ge`Lt`Gt;i]};

/ Scala: add = add ("+" | "-") mult | mult
.aqc.parse.addExpr:{[i] .aqc.parse.leftChain[.aqc.parse.multExpr;(enlist "+";enlist "-")!`Plus`Minus;i]};

/ Scala: mult = mult ("*" | "/") pow | pow
.aqc.parse.multExpr:{[i] .aqc.parse.leftChain[.aqc.parse.powExpr;(enlist "*";enlist "/")!`Times`Div;i]};

/ Scala: pow = (unary "^") pow | unary
/ Grouped to the right: 2^3^4 is 2^(3^4).
.aqc.parse.powExpr:{[i]
  left:.aqc.parse.unaryExpr i;
  if[not left`ok; :left];
  caret:.aqc.parse.delim[left`next;"^"];
  if[not caret`ok; :left];
  right:.aqc.parse.powExpr caret`next;
  if[not right`ok; :left];                      / Scala falls back to plain unary
  tree:.aqc.ast.binExpr[`Exp;left`node;right`node];
  .aqc.parse.positioned[i;.aqc.parse.ok[tree;right`next]]};

/ Scala: unary = "-" baseExp | baseExp       (see negate)
/ Scala also lists "!" here, but the lexer has no "!" token (only "!="),
/ so that branch can never match and is left out.
/ Note that "-" binds tighter than "^": -x^2 is (-x)^2.
.aqc.parse.unaryExpr:{[i]
  minus:.aqc.parse.delim[i;"-"];
  if[minus`ok;
    r:.aqc.parse.baseExp minus`next;
    if[r`ok; :.aqc.parse.positioned[i;.aqc.parse.ok[.aqc.parse.negate r`node;r`next]]]];
  .aqc.parse.positioned[i;.aqc.parse.baseExp i]};

/ negate[e]
/   -e. A number literal is negated in place (IntLit 5 -> IntLit -5, also
/   for "-(5)"); anything else becomes UnExpr(Neg, e). The new node has no
/   position, so unary gives it the position of the "-".
.aqc.parse.negate:{[e]
  if[.aqc.ast.isNode e;
    if[(e`node) in `IntLit`FloatLit; :.aqc.ast.lit[e`node;neg e`v]]];
  .aqc.ast.unExpr[`Neg;e]};

/ Scala: baseExp = lit | indexExpr | "(" expr ")" | caseExpr | funCall | tableExp | id
/        indexExpr = baseExp "[" indexOp "]"
/ indexExpr is left-recursive (it starts with baseExp). With Scala's packrat
/ parser that means: parse a baseExp, then keep adding [ ... ] suffixes
/ while they parse: f(x)[odd][every 2]. One Scala quirk is kept: lit is
/ tried first and a literal is never indexed, so 5[even] stops after 5.
/ Written as "parse the base once, then loop over suffixes" so that no
/ tokens are parsed twice (Scala re-parses the base but caches it).
.aqc.parse.baseExp:{[i]
  r:.aqc.parse.lit i;
  if[r`ok; :.aqc.parse.positioned[i;r]];
  r:.aqc.parse.firstOf[(.aqc.parse.parens;.aqc.parse.caseExpr;.aqc.parse.funCall;.aqc.parse.tableExp;.aqc.parse.id);i];
  if[not r`ok; :r];
  r:.aqc.parse.positioned[i;r];
  while[(suffix:.aqc.parse.indexSuffix r`next)`ok;
    tree:.aqc.ast.arrayIndex[r`node;suffix`node];
    r:.aqc.parse.positioned[i;.aqc.parse.ok[tree;suffix`next]]];
  r};

/ "(" expr ")" and "[" indexOp "]"; the node is what is inside
.aqc.parse.parens:{[i] .aqc.parse.between["(";.aqc.parse.expr;")";i]};
.aqc.parse.indexSuffix:{[i] .aqc.parse.between["[";.aqc.parse.indexOp;"]";i]};

/ Scala: indexOp = EVEN | ODD | EVERY numericLit
.aqc.parse.indexOp:{[i]
  r:.aqc.parse.pick[i;`EVEN`ODD!`Even`Odd];
  if[r`ok; :r];
  r:.aqc.parse.kw[i;`EVERY];
  if[not r`ok; :r];
  n:.aqc.parse.numericLit r`next;
  if[not n`ok; :n];
  .aqc.parse.ok[.aqc.ast.every "J"$n`node;n`next]};   / "J"$ reads a long

/ Scala: caseExpr = CASE expr? whenThen+ (ELSE expr)? END
/     CASE x WHEN 1 THEN 2 ELSE 3 END  ->  Case(Some(x), List(IfThen(1,2)), Some(3))
.aqc.parse.caseExpr:{[i]
  r:.aqc.parse.kw[i;`CASE];
  if[not r`ok; :r];
  j:r`next;
  / optional expression right after CASE
  cond:`None;
  r:.aqc.parse.expr j;
  if[r`ok; cond:.aqc.ast.some r`node; j:r`next];
  / one or more WHEN ... THEN ...
  whens:();
  while[(r:.aqc.parse.whenThen j)`ok;
    whens:.aqc.ast.append[whens;r`node];
    j:r`next];
  if[0 = count whens; :r];                      / not even one: fail like it did
  / optional ELSE expr
  elseExpr:`None;
  r:.aqc.parse.kw[j;`ELSE];
  if[r`ok;
    r:.aqc.parse.expr r`next;
    if[r`ok; elseExpr:.aqc.ast.some r`node; j:r`next]];
  r:.aqc.parse.kw[j;`END];
  if[not r`ok; :r];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.case[cond;whens;elseExpr];r`next]]};

/ Scala: whenThen = WHEN expr THEN expr  -> IfThen(c, t)
/ (Scala's positioned here wraps only the condition, so IfThen itself
/ never gets a position.)
.aqc.parse.whenThen:{[i]
  r:.aqc.parse.kw[i;`WHEN];
  if[not r`ok; :r];
  c:.aqc.parse.expr r`next;
  if[not c`ok; :c];
  r:.aqc.parse.kw[c`next;`THEN];
  if[not r`ok; :r];
  t:.aqc.parse.expr r`next;
  if[not t`ok; :t];
  .aqc.parse.ok[.aqc.ast.ifThen[c`node;t`node];t`next]};

/ Scala: funCall = ident "(" repsep(expr, ",") ")" | builtin "(" ... ")"
/ A built-in function is a keyword marked fun = true (keywords.q); its
/ name is stored in upper case: sum(x) -> FunCall(SUM, ...).
.aqc.parse.funCall:{[i]
  name:.aqc.parse.ident i;
  if[not name`ok;
    name:.aqc.parse.builtin i;
    if[not name`ok; :name];
    name[`node]:upper name`node];
  args:.aqc.parse.argList name`next;
  if[not args`ok; :args];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.funCall[name`node;args`node];args`next]]};

/ builtin[i]: token i is the name of a built-in function (SUM, sum, ...)
/ The spellings are worked out once, when this file loads, not on every
/ call: funCall tries builtin at every identifier-shaped spot.
.aqc.parse.builtinNames:raze .aqc.parse.spellings each .aqc.kw.functions;
.aqc.parse.builtin:{[i] .aqc.parse.accept[i;.aqc.parse.builtinNames]};

/ argList[i]
/   "(" then zero or more expressions separated by "," then ")".
/   The node is the list of expressions.
.aqc.parse.argList:{[i] .aqc.parse.between["(";.aqc.parse.sepBy[.aqc.parse.expr;.aqc.parse.comma];")";i]};

/ comma[i]: the delimiter "," (a rule, for sepBy and sepBy1)
.aqc.parse.comma:{[i] .aqc.parse.delim[i;enlist ","]};

/ sepBy1[rule; separator; i]
/   Scala's rep1sep(rule, separator): one or more rule matches separated by
/   separator matches. rule and separator are both rules (functions of i).
/   The node is the list of what rule matched; the separators are dropped.
/     sepBy1[expr; comma; ...] on "1, 2)"  gives the list (1; 2), next at ")"
/   If a separator is not followed by a match, the list ends before that
/   separator (Scala backtracks the same way).
.aqc.parse.sepBy1:{[rule;separator;i]
  r:rule i;
  if[not r`ok; :r];
  items:.aqc.ast.append[();r`node];
  j:r`next;
  while[1b;
    sep:separator j;
    if[not sep`ok; :.aqc.parse.ok[items;j]];
    r:rule sep`next;
    if[not r`ok; :.aqc.parse.ok[items;j]];      / stop before the separator
    items:.aqc.ast.append[items;r`node];
    j:r`next]};

/ sepBy[rule; separator; i]
/   Scala's repsep: like sepBy1, but zero matches is fine too (the empty
/   list), so it always succeeds.
.aqc.parse.sepBy:{[rule;separator;i]
  r:.aqc.parse.sepBy1[rule;separator;i];
  $[r`ok; r; .aqc.parse.ok[();i]]};

/ many1[rule; i]
/   Scala's rule.+ (rep1): one or more rule matches in a row, with nothing
/   between them. The node is the list of matches.
.aqc.parse.many1:{[rule;i]
  r:rule i;
  if[not r`ok; :r];
  items:();
  while[r`ok;
    items:.aqc.ast.append[items;r`node];
    i:r`next;
    r:rule i];
  .aqc.parse.ok[items;i]};

/ parenList[rule; i]
/   "(" then one or more rule matches separated by "," then ")".
/   The node is the list of matches.
.aqc.parse.parenList:{[rule;i] .aqc.parse.between["(";.aqc.parse.sepBy1[rule;.aqc.parse.comma];")";i]};

/ Scala: tableExp = ROWID | ident "." ident | "*"
.aqc.parse.tableExp:{[i]
  if[(.aqc.parse.kw[i;`ROWID])`ok; :.aqc.parse.ok[`RowId;i + 1]];
  r:.aqc.parse.columnAccess i;
  if[r`ok; :.aqc.parse.positioned[i;r]];
  star:.aqc.parse.delim[i;"*"];
  if[star`ok; :.aqc.parse.ok[`WildCard;i + 1]];
  star};

/ ident "." ident  ->  ColumnAccess(table, column)
.aqc.parse.columnAccess:{[i]
  t:.aqc.parse.ident i;
  if[not t`ok; :t];
  dot:.aqc.parse.delim[t`next;"."];
  if[not dot`ok; :dot];
  c:.aqc.parse.ident dot`next;
  if[not c`ok; :c];
  .aqc.parse.ok[.aqc.ast.columnAccess[t`node;c`node];c`next]};

/ Scala: id = ident  -> Id(name)
.aqc.parse.id:{[i]
  r:.aqc.parse.ident i;
  if[not r`ok; :r];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.id r`node;r`next]]};

/ Scala: lit = numericLit | timestamp | date | stringLit | bool
/ A number with a "." is a FloatLit, else an IntLit ("007" -> 7).
/ DIVERGES FROM SCALA on purpose: a timestamp is a TimestampLit (Scala's
/ lexer turns it into a string, so Scala makes a StringLit).
.aqc.parse.lit:{[i]
  t:.aqc.parse.token i;
  k:t`kind;
  s:t`text;
  node:$[k = `NumericLit; $["." in s; .aqc.ast.lit[`FloatLit;"F"$s]; .aqc.ast.lit[`IntLit;"J"$s]];
    k = `Timestamp; .aqc.ast.lit[`TimestampLit;s];
    k = `Date; .aqc.ast.lit[`DateLit;s];
    k = `StringLit; .aqc.ast.lit[`StringLit;s];
    (::)];
  if[not (::) ~ node; :.aqc.parse.positioned[i;.aqc.parse.ok[node;i + 1]]];
  .aqc.parse.bool i};

/ Scala: bool = TRUE | FALSE  -> BooleanLit
.aqc.parse.bool:{[i]
  r:.aqc.parse.pick[i;`TRUE`FALSE!10b];          / 10b is the list (1b; 0b)
  if[not r`ok; :r];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.lit[`BooleanLit;r`node];r`next]]};


/ ---------------------------------------------------------------------------
/ Queries
/ Scala: fullQuery, localQuery, topApply, query and the clause rules below
/ them. Several Scala rule names are q built-ins (from, where, group), so
/ those rules are called fromClause, whereClause and groupItem here.
/ ---------------------------------------------------------------------------

/ Scala: fullQuery = (WITH localQuery+)? topApply   -> Query(locals, main)
/     WITH x AS (SELECT a FROM t) SELECT a FROM x
/ The local queries follow each other with nothing between them (no ",").
.aqc.parse.fullQuery:{[i]
  locals:();
  j:i;
  r:.aqc.parse.kw[i;`WITH];
  if[r`ok;
    r:.aqc.parse.many1[.aqc.parse.localQuery;r`next];
    / if no local query follows WITH, Scala drops the whole optional part
    / and tries the main query at WITH (which then fails there)
    if[r`ok; locals:r`node; j:r`next]];
  r:.aqc.parse.topApply j;
  if[not r`ok; :r];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.query[locals;r`node];r`next]]};

/ Scala: localQuery = ident ("(" rep1sep(ident, ",") ")")? AS "(" topApply ")"
/ The node is Tuple(name, column names, query):
/     x(a, b) AS (SELECT a FROM t)   ->   ("x"; ("a";"b"); <the query>)
.aqc.parse.localQuery:{[i]
  name:.aqc.parse.ident i;
  if[not name`ok; :name];
  j:name`next;
  / optional column names (colNames, because cols is a q built-in)
  colNames:();
  r:.aqc.parse.parenList[.aqc.parse.ident;j];
  if[r`ok; colNames:r`node; j:r`next];
  r:.aqc.parse.kw[j;`AS];
  if[not r`ok; :r];
  q:.aqc.parse.between["(";.aqc.parse.topApply;")";r`next];
  if[not q`ok; :q];
  .aqc.parse.ok[.aqc.ast.tuple (name`node;colNames;q`node);q`next]};

/ Scala: topApply = (SHOW | EXEC ARRAYS | DISTINCT) "(" query ")" | query
/ Applies a function to the result of a whole query:
/     SHOW(SELECT a FROM t)   ->   TopApply("SHOW", <the query>)
.aqc.parse.topApply:{[i]
  .aqc.parse.positioned[i;.aqc.parse.firstOf[(.aqc.parse.topApplyCall;.aqc.parse.query);i]]};

/ the first branch of topApply: name "(" query ")"
.aqc.parse.topApplyCall:{[i]
  f:.aqc.parse.topApplyName i;
  if[not f`ok; :f];
  q:.aqc.parse.between["(";.aqc.parse.query;")";f`next];
  if[not q`ok; :q];
  .aqc.parse.ok[.aqc.ast.topApply[f`node;q`node];q`next]};

/ SHOW -> "SHOW", EXEC ARRAYS -> "EXEC_ARRAYS", DISTINCT -> "DISTINCT"
.aqc.parse.topApplyName:{[i]
  if[(.aqc.parse.kw[i;`SHOW])`ok; :.aqc.parse.ok["SHOW";i + 1]];
  r:.aqc.parse.kw[i;`EXEC];
  if[r`ok;
    r:.aqc.parse.kw[r`next;`ARRAYS];
    if[r`ok; :.aqc.parse.ok["EXEC_ARRAYS";r`next]]];
  r:.aqc.parse.kw[i;`DISTINCT];
  if[not r`ok; :r];
  .aqc.parse.ok["DISTINCT";r`next]};

/ Scala: query = SELECT DISTINCT? rep1sep(projection, ",") FROM from
/                (ASSUMING order)? (WHERE where)?
/                (GROUP BY groupBy (HAVING rep1sep(expr, "AND"))?)?
/ The tree is built from the inside out, one clause at a time:
/     SELECT a FROM t ASSUMING ASC a WHERE a > 1
/     ->  Project(Filter(SortBy(Table(t), ...), ...), ...)
/ and DISTINCT wraps the whole thing in TopApply("DISTINCT", ...).
/ An optional clause that does not parse is simply left out (Scala's .?);
/ whatever it left unparsed is then reported as the error.
.aqc.parse.query:{[i]
  r:.aqc.parse.kw[i;`SELECT];
  if[not r`ok; :r];
  j:r`next;
  isDistinct:0b;                  / 0b is false, 1b is true
  r:.aqc.parse.kw[j;`DISTINCT];
  if[r`ok; isDistinct:1b; j:r`next];
  ps:.aqc.parse.sepBy1[.aqc.parse.projection;.aqc.parse.comma;j];
  if[not ps`ok; :ps];
  r:.aqc.parse.kw[ps`next;`FROM];
  if[not r`ok; :r];
  r:.aqc.parse.fromClause r`next;
  if[not r`ok; :r];
  tree:r`node;
  j:r`next;
  r:.aqc.parse.assumingClause j;
  if[r`ok; tree:.aqc.ast.sortBy[tree;r`node]; j:r`next];
  r:.aqc.parse.whereClauseKw j;
  if[r`ok; tree:.aqc.ast.filter[tree;r`node]; j:r`next];
  r:.aqc.parse.groupClause j;
  if[r`ok; tree:.aqc.ast.groupBy[tree;r[`node] 0;r[`node] 1]; j:r`next];
  tree:.aqc.ast.project[tree;ps`node];
  if[isDistinct; tree:.aqc.ast.topApply["DISTINCT";tree]];
  .aqc.parse.positioned[i;.aqc.parse.ok[tree;j]]};

/ ASSUMING order   (the node is the order list)
.aqc.parse.assumingClause:{[i]
  r:.aqc.parse.kw[i;`ASSUMING];
  if[not r`ok; :r];
  .aqc.parse.order r`next};

/ WHERE where   (the node is the list of conditions)
.aqc.parse.whereClauseKw:{[i]
  r:.aqc.parse.kw[i;`WHERE];
  if[not r`ok; :r];
  .aqc.parse.whereClause r`next};

/ GROUP BY groupBy (HAVING rep1sep(expr, "AND"))?
/ The node is a 2-item list: (the groups; the HAVING conditions, maybe empty).
/ HAVING's conditions are plain expressions (no IN, BETWEEN, ...), and only
/ an upper-case AND separates them: Scala wrote "AND" as a string here, which
/ matches that exact spelling, not the AND keyword.
.aqc.parse.groupClause:{[i]
  r:.aqc.parse.kw[i;`GROUP];
  if[not r`ok; :r];
  r:.aqc.parse.kw[r`next;`BY];
  if[not r`ok; :r];
  gs:.aqc.parse.groupBy r`next;
  if[not gs`ok; :gs];
  having:();
  j:gs`next;
  r:.aqc.parse.kw[j;`HAVING];
  if[r`ok;
    r:.aqc.parse.sepBy1[.aqc.parse.expr;.aqc.parse.upperAnd;r`next];
    if[r`ok; having:r`node; j:r`next]];
  .aqc.parse.ok[(gs`node;having);j]};

/ upperAnd[i]: exactly "AND" (not "and"), see groupClause
.aqc.parse.upperAnd:{[i] .aqc.parse.delim[i;"AND"]};

/ Scala: projection = expr (AS ident)?   -> Tuple(expr, `None or Some(name))
/     a + 1 AS b   ->   Tuple(BinExpr(...), Some("b"))
.aqc.parse.projection:{[i]
  e:.aqc.parse.expr i;
  if[not e`ok; :e];
  alias:`None;
  j:e`next;
  r:.aqc.parse.kw[j;`AS];
  if[r`ok;
    r:.aqc.parse.ident r`next;
    if[r`ok; alias:.aqc.ast.some r`node; j:r`next]];
  .aqc.parse.ok[.aqc.ast.tuple (e`node;alias);j]};

/ Scala: groupBy = rep1sep(group, ",")
/        group = expr (AS ident)?     (the same shape as projection)
.aqc.parse.groupBy:{[i] .aqc.parse.sepBy1[.aqc.parse.groupItem;.aqc.parse.comma;i]};
.aqc.parse.groupItem:{[i] .aqc.parse.projection i};

/ Scala: order = rep1sep(orderPair, ",")
.aqc.parse.order:{[i] .aqc.parse.sepBy1[.aqc.parse.orderPair;.aqc.parse.comma;i]};

/ Scala: orderPair = (ASC | DESC) expr   -> Tuple(`Asc or `Desc, expr)
.aqc.parse.orderPair:{[i]
  dir:.aqc.parse.pick[i;`ASC`DESC!`Asc`Desc];
  if[not dir`ok; :dir];
  e:.aqc.parse.expr dir`next;
  if[not e`ok; :e];
  .aqc.parse.ok[.aqc.ast.tuple (dir`node;e`node);e`next]};


/ ---------------------------------------------------------------------------
/ FROM: tables, function calls and joins
/ ---------------------------------------------------------------------------

/ Scala: from = from INNER JOIN simpleTable USING using
/            | from FULL OUTER JOIN simpleTable USING using
/            | from "," simpleTable
/            | bottomApply
/            | simpleTable
/ Left-recursive like the operator chains: parse one table (or function
/ call), then keep adding joins while one parses. Joins group to the left:
/     t, u INNER JOIN v USING k   ->   Join(InnerJoinUsing, Join(Cross, t, u), v, k)
/ Every Join gets the position of the first table (positioned, as in Scala).
.aqc.parse.fromClause:{[i]
  r:.aqc.parse.firstOf[(.aqc.parse.bottomApply;.aqc.parse.simpleTable);i];
  if[not r`ok; :r];
  r:.aqc.parse.positioned[i;r];
  while[1b;
    join:.aqc.parse.firstOf[(.aqc.parse.innerJoin;.aqc.parse.outerJoin;.aqc.parse.crossJoin);r`next];
    if[not join`ok; :r];
    / join`node is (join type; right table; USING columns)
    parts:join`node;
    tree:.aqc.ast.join[parts 0;r`node;parts 1;parts 2];
    r:.aqc.parse.positioned[i;.aqc.parse.ok[tree;join`next]]];
  r};

/ The part of a join after the left table. Each gives the node
/ (join type; right table; USING columns).

/ INNER JOIN simpleTable USING using
.aqc.parse.innerJoin:{[i]
  r:.aqc.parse.kw[i;`INNER];
  if[not r`ok; :r];
  r:.aqc.parse.kw[r`next;`JOIN];
  if[not r`ok; :r];
  .aqc.parse.joinRest[`InnerJoinUsing;r`next]};

/ FULL OUTER JOIN simpleTable USING using
.aqc.parse.outerJoin:{[i]
  r:.aqc.parse.kw[i;`FULL];
  if[not r`ok; :r];
  r:.aqc.parse.kw[r`next;`OUTER];
  if[not r`ok; :r];
  r:.aqc.parse.kw[r`next;`JOIN];
  if[not r`ok; :r];
  .aqc.parse.joinRest[`FullOuterJoinUsing;r`next]};

/ joinRest[jt; i]: simpleTable USING using, after the JOIN keyword
.aqc.parse.joinRest:{[jt;i]
  t:.aqc.parse.simpleTable i;
  if[not t`ok; :t];
  r:.aqc.parse.kw[t`next;`USING];
  if[not r`ok; :r];
  u:.aqc.parse.using r`next;
  if[not u`ok; :u];
  .aqc.parse.ok[(jt;t`node;u`node);u`next]};

/ "," simpleTable: a cross join, with no USING columns
.aqc.parse.crossJoin:{[i]
  r:.aqc.parse.comma i;
  if[not r`ok; :r];
  t:.aqc.parse.simpleTable r`next;
  if[not t`ok; :t];
  .aqc.parse.ok[(`Cross;t`node;());t`next]};

/ Scala: using = "(" repsep(id, ",") ")" | id
/ The node is always a list: USING k  ->  a 1-item list.
.aqc.parse.using:{[i]
  ids:.aqc.parse.between["(";.aqc.parse.sepBy[.aqc.parse.id;.aqc.parse.comma];")";i];
  if[ids`ok; :ids];
  / no "(", or no ")" after the ids: try a single id instead
  r:.aqc.parse.id i;
  if[not r`ok; :r];
  .aqc.parse.ok[.aqc.ast.append[();r`node];r`next]};

/ Scala: simpleTable = ident (AS? ident)?   -> Table(name, alias)
/ The AS is optional: t, t AS u and t u are all fine.
.aqc.parse.simpleTable:{[i]
  name:.aqc.parse.ident i;
  if[not name`ok; :name];
  alias:`None;
  j:name`next;
  k:j;                            / where the alias name would start
  r:.aqc.parse.kw[j;`AS];
  if[r`ok; k:r`next];
  r:.aqc.parse.ident k;
  if[r`ok; alias:.aqc.ast.some r`node; j:r`next];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.table[name`node;alias];j]]};

/ Scala: bottomApply = funCall   -> BottomApply(f, args)
/ A function call used as a table: FROM f(1, 2). It can't have an alias.
.aqc.parse.bottomApply:{[i]
  r:.aqc.parse.funCall i;
  if[not r`ok; :r];
  call:r`node;
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.bottomApply[call`f;call`args];r`next]]};


/ ---------------------------------------------------------------------------
/ WHERE: conditions and predicates
/ ---------------------------------------------------------------------------

/ Scala: where = rep1sep(predicate | expr, AND)
/ The node is the list of conditions. Here AND is the keyword (AND or and).
.aqc.parse.whereClause:{[i] .aqc.parse.sepBy1[.aqc.parse.condition;.aqc.parse.andKw;i]};

/ condition[i]: predicate | expr
.aqc.parse.condition:{[i] .aqc.parse.firstOf[(.aqc.parse.predicate;.aqc.parse.expr);i]};

/ andKw[i]: the keyword AND (either spelling)
.aqc.parse.andKw:{[i] .aqc.parse.kw[i;`AND]};

/ Scala: predicate =
/     expr NOT? (BETWEEN expr AND expr | IN (expr | "(" rep1sep(expr, ",") ")") | LIKE expr)
/   | expr IS NOT? bool
/   | expr IS NOT? NULL
/   | range NOT? OVERLAPS range
/ Predicates become function calls named after the keyword, with the
/ tested expression first; NOT wraps the call in FunCall("NOT", ...):
/     x NOT IN (1, 2)   ->   FunCall(NOT, List(FunCall(IN, List(x, 1, 2))))
/     x IS NULL         ->   FunCall(NULL, List(x))
/ except x IS [NOT] TRUE/FALSE, which becomes BinExpr(Eq or Neq, x, bool).
/ The first three branches all start with expr. Scala parses it once and
/ reuses it (its packrat parser caches results); here it is parsed once and
/ then each possible ending is tried.
.aqc.parse.predicate:{[i]
  e:.aqc.parse.expr i;
  if[e`ok;
    r:.aqc.parse.firstOf[(.aqc.parse.inLikeBetween[e`node];.aqc.parse.isBool[e`node];.aqc.parse.isNull[e`node]);e`next];
    if[r`ok; :.aqc.parse.positioned[i;r]]];
  .aqc.parse.positioned[i;.aqc.parse.overlaps i]};

/ wrapNot[negated; e]: FunCall("NOT", List(e)) if negated, else e
.aqc.parse.wrapNot:{[negated;e]
  $[negated; .aqc.ast.funCall["NOT";.aqc.ast.append[();e]]; e]};

/ optNot[i]: an optional NOT. Always succeeds; the node is 1b if NOT is there.
.aqc.parse.optNot:{[i]
  r:.aqc.parse.kw[i;`NOT];
  $[r`ok; .aqc.parse.ok[1b;r`next]; .aqc.parse.ok[0b;i]]};

/ inLikeBetween[e; i]: NOT? (BETWEEN a AND b | IN ... | LIKE p), after e.
/ (Called as inLikeBetween[e] with e fixed, which makes it a rule of i.)
.aqc.parse.inLikeBetween:{[e;i]
  n:.aqc.parse.optNot i;
  r:.aqc.parse.firstOf[(.aqc.parse.betweenTail;.aqc.parse.inTail;.aqc.parse.likeTail);n`next];
  if[not r`ok; :r];
  / r`node is (name; arguments after e)
  args:.aqc.ast.concat[.aqc.ast.append[();e];r[`node] 1];
  call:.aqc.ast.funCall[r[`node] 0;args];
  .aqc.parse.ok[.aqc.parse.wrapNot[n`node;call];r`next]};

/ BETWEEN a AND b   -> ("BETWEEN"; (a; b))
.aqc.parse.betweenTail:{[i]
  r:.aqc.parse.kw[i;`BETWEEN];
  if[not r`ok; :r];
  lo:.aqc.parse.expr r`next;
  if[not lo`ok; :lo];
  r:.aqc.parse.kw[lo`next;`AND];
  if[not r`ok; :r];
  hi:.aqc.parse.expr r`next;
  if[not hi`ok; :hi];
  .aqc.parse.ok[("BETWEEN";.aqc.ast.append[.aqc.ast.append[();lo`node];hi`node]);hi`next]};

/ IN expr  or  IN "(" rep1sep(expr, ",") ")"   -> ("IN"; the expressions)
/ A single expression is tried first, so IN (1) is IN with the expression (1).
.aqc.parse.inTail:{[i]
  r:.aqc.parse.kw[i;`IN];
  if[not r`ok; :r];
  one:.aqc.parse.expr r`next;
  if[one`ok; :.aqc.parse.ok[("IN";.aqc.ast.append[();one`node]);one`next]];
  many:.aqc.parse.parenList[.aqc.parse.expr;r`next];
  if[not many`ok; :many];
  .aqc.parse.ok[("IN";many`node);many`next]};

/ LIKE expr   -> ("LIKE"; (expr))
.aqc.parse.likeTail:{[i]
  r:.aqc.parse.kw[i;`LIKE];
  if[not r`ok; :r];
  p:.aqc.parse.expr r`next;
  if[not p`ok; :p];
  .aqc.parse.ok[("LIKE";.aqc.ast.append[();p`node]);p`next]};

/ isBool[e; i]: IS NOT? TRUE/FALSE after e  ->  BinExpr(Eq or Neq, e, bool)
.aqc.parse.isBool:{[e;i]
  r:.aqc.parse.kw[i;`IS];
  if[not r`ok; :r];
  n:.aqc.parse.optNot r`next;
  b:.aqc.parse.bool n`next;
  if[not b`ok; :b];
  op:$[n`node; `Neq; `Eq];
  .aqc.parse.ok[.aqc.ast.binExpr[op;e;b`node];b`next]};

/ isNull[e; i]: IS NOT? NULL after e  ->  FunCall("NULL", List(e)), NOT-wrapped
.aqc.parse.isNull:{[e;i]
  r:.aqc.parse.kw[i;`IS];
  if[not r`ok; :r];
  n:.aqc.parse.optNot r`next;
  r:.aqc.parse.kw[n`next;`NULL];
  if[not r`ok; :r];
  call:.aqc.ast.funCall["NULL";.aqc.ast.append[();e]];
  .aqc.parse.ok[.aqc.parse.wrapNot[n`node;call];r`next]};

/ overlaps[i]: range NOT? OVERLAPS range
/   ->  FunCall("OVERLAPS", List(a, b, c, d)), NOT-wrapped
/     (a, b) OVERLAPS (c, d)
.aqc.parse.overlaps:{[i]
  l:.aqc.parse.range i;
  if[not l`ok; :l];
  n:.aqc.parse.optNot l`next;
  r:.aqc.parse.kw[n`next;`OVERLAPS];
  if[not r`ok; :r];
  rr:.aqc.parse.range r`next;
  if[not rr`ok; :rr];
  call:.aqc.ast.funCall["OVERLAPS";.aqc.ast.concat[l`node;rr`node]];
  .aqc.parse.ok[.aqc.parse.wrapNot[n`node;call];rr`next]};

/ Scala: range = "(" expr "," expr ")"   -> the list of the two expressions
.aqc.parse.range:{[i]
  r:.aqc.parse.delim[i;"("];
  if[not r`ok; :r];
  lo:.aqc.parse.expr r`next;
  if[not lo`ok; :lo];
  r:.aqc.parse.comma lo`next;
  if[not r`ok; :r];
  hi:.aqc.parse.expr r`next;
  if[not hi`ok; :hi];
  r:.aqc.parse.delim[hi`next;")"];
  if[not r`ok; :r];
  .aqc.parse.ok[.aqc.ast.append[.aqc.ast.append[();lo`node];hi`node];r`next]};


/ ---------------------------------------------------------------------------
/ Statements and the whole program
/ Scala: program and the rules for each kind of top-level statement. insert,
/ update and delete are q built-ins, so those rules are called insertStmt,
/ updateStmt and deleteStmt here.
/ ---------------------------------------------------------------------------

/ Scala: program = rep1(io | fullQuery | verbatim | udf | delete | update
/                       | dropTrigger | trigger | create | insert)
/                  ^^ rewriteLocalStringConstants
/ The node is the list of statements, after the string-constant rewrite of
/ WITH queries (rewrite.q).
.aqc.parse.program:{[i]
  r:.aqc.parse.many1[.aqc.parse.topLevel;i];
  if[not r`ok; :r];
  .aqc.parse.ok[.aqc.rewrite.rewriteProgram r`node;r`next]};

/ topLevel[i]: one statement, the first kind that parses (in Scala's order:
/ io comes before fullQuery because "SELECT ... INTO OUTFILE" starts like a
/ query, and trigger before create because both start with CREATE)
.aqc.parse.topLevel:{[i]
  .aqc.parse.firstOf[(.aqc.parse.io;.aqc.parse.fullQuery;.aqc.parse.verbatim;.aqc.parse.udf;
    .aqc.parse.deleteStmt;.aqc.parse.updateStmt;.aqc.parse.dropTrigger;.aqc.parse.trigger;
    .aqc.parse.create;.aqc.parse.insertStmt);i]};

/ kws[i; words]
/   The keywords words (a list of symbols), one after the other:
/     kws[i; `GROUP`BY]  is  kw[i;`GROUP], then kw[...;`BY]
/   The node is the text of the last one.
.aqc.parse.kws:{[i;words]
  r:.aqc.parse.kw[i;first words];
  k:1;
  while[k < count words;
    if[not r`ok; :r];
    r:.aqc.parse.kw[r`next;words k];
    k+:1];
  r};

/ Scala: verbatim = a Verbatim token   -> VerbatimCode(the q code)
/     <q> f:{x} </q>   ->   VerbatimCode(" f:{x} ")
.aqc.parse.verbatim:{[i]
  r:.aqc.parse.tokenOfKind[i;`Verbatim;"verbatim code"];
  if[not r`ok; :r];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.verbatimCode r`node;r`next]]};


/ ---- CREATE TABLE -----------------------------------------------------------

/ Scala: create = CREATE TABLE ident (schema | fullQuery)
/     CREATE TABLE t (a INT, b FLOAT)   ->  Create("t", Left(schema))
/     CREATE TABLE t SELECT a FROM u    ->  Create("t", Right(query))
/ (There is no AS before the query.)
.aqc.parse.create:{[i]
  r:.aqc.parse.kws[i;`CREATE`TABLE];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  r:.aqc.parse.schema name`next;
  if[r`ok;
    tree:.aqc.ast.create[name`node;.aqc.ast.left r`node];
    :.aqc.parse.positioned[i;.aqc.parse.ok[tree;r`next]]];
  r:.aqc.parse.fullQuery name`next;
  if[not r`ok; :r];
  tree:.aqc.ast.create[name`node;.aqc.ast.right r`node];
  .aqc.parse.positioned[i;.aqc.parse.ok[tree;r`next]]};

/ Scala: schema = "(" rep1sep(schemaEntry, ",") ")"
.aqc.parse.schema:{[i] .aqc.parse.parenList[.aqc.parse.schemaEntry;i]};

/ Scala: schemaEntry = ident typeLabel   -> Tuple(name, type)
.aqc.parse.schemaEntry:{[i]
  name:.aqc.parse.ident i;
  if[not name`ok; :name];
  t:.aqc.parse.typeLabel name`next;
  if[not t`ok; :t];
  .aqc.parse.ok[.aqc.ast.tuple (name`node;t`node);t`next]};

/ Scala: typeLabel = INT | FLOAT | TIMESTAMP | DATE | BOOLEAN | STRING
/ The node is the Scala type object, e.g. `TypeInt. These keywords are
/ always upper case (keywords.q, alwaysUpper): "int" is not a type.
.aqc.parse.typeNames:`INT`FLOAT`TIMESTAMP`DATE`BOOLEAN`STRING!`TypeInt`TypeFloat`TypeTimestamp`TypeDate`TypeBoolean`TypeString;
.aqc.parse.typeLabel:{[i] .aqc.parse.pick[i;.aqc.parse.typeNames]};


/ ---- INSERT -----------------------------------------------------------------

/ Scala: insert = INSERT INTO ident modInsert? (ASSUMING order)? srcInsert
/   -> Insert(table, order, columns, source)
/     INSERT INTO t (a, b) VALUES (1, 2)
/     INSERT INTO t ASSUMING ASC a SELECT a FROM u
.aqc.parse.insertStmt:{[i]
  r:.aqc.parse.kws[i;`INSERT`INTO];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  j:name`next;
  / optional column list: "(" repsep(ident, ",") ")"
  modifier:();
  r:.aqc.parse.columnList j;
  if[r`ok; modifier:r`node; j:r`next];
  order:();
  r:.aqc.parse.assumingClause j;
  if[r`ok; order:r`node; j:r`next];
  src:.aqc.parse.srcInsert j;
  if[not src`ok; :src];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.insertStmt[name`node;order;modifier;src`node];src`next]]};

/ columnList[i]: "(" zero or more identifiers separated by "," ")"
/ (Scala: modInsert)
/   sepBy[ident; comma] leaves out sepBy's last argument i, so it is a rule.
.aqc.parse.columnList:{[i]
  .aqc.parse.between["(";.aqc.parse.sepBy[.aqc.parse.ident;.aqc.parse.comma];")";i]};

/ Scala: srcInsert = VALUES "(" repsep(expr, ",") ")"   -> Left(values)
/                  | fullQuery                          -> Right(query)
.aqc.parse.srcInsert:{[i]
  r:.aqc.parse.kw[i;`VALUES];
  if[r`ok;
    vals:.aqc.parse.argList r`next;     / "(" repsep(expr, ",") ")", as for f(...)
    if[vals`ok; :.aqc.parse.ok[.aqc.ast.left vals`node;vals`next]]];
  r:.aqc.parse.fullQuery i;
  if[not r`ok; :r];
  .aqc.parse.ok[.aqc.ast.right r`node;r`next]};


/ ---- UPDATE and DELETE ------------------------------------------------------

/ Scala: update = UPDATE ident SET rep1sep(elemUpdate, ",") (ASSUMING order)?
/                 (WHERE where)? (GROUP BY rep1sep(expr, ",")
/                 (HAVING rep1sep(expr, "AND"))?)?
/   -> Update(table, assignments, order, where, group by, having)
/ A missing clause is an empty list.
.aqc.parse.updateStmt:{[i]
  r:.aqc.parse.kw[i;`UPDATE];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  r:.aqc.parse.kw[name`next;`SET];
  if[not r`ok; :r];
  assigns:.aqc.parse.sepBy1[.aqc.parse.elemUpdate;.aqc.parse.comma;r`next];
  if[not assigns`ok; :assigns];
  j:assigns`next;
  order:();
  r:.aqc.parse.assumingClause j;
  if[r`ok; order:r`node; j:r`next];
  conds:();
  r:.aqc.parse.whereClauseKw j;
  if[r`ok; conds:r`node; j:r`next];
  groups:();
  having:();
  r:.aqc.parse.modGroupBy[0b;j];
  if[r`ok; groups:r[`node] 0; having:r[`node] 1; j:r`next];
  tree:.aqc.ast.updateStmt[name`node;assigns`node;order;conds;groups;having];
  .aqc.parse.positioned[i;.aqc.parse.ok[tree;j]]};

/ Scala: elemUpdate = ident "=" expr   -> Tuple(column, expr)
.aqc.parse.elemUpdate:{[i]
  name:.aqc.parse.ident i;
  if[not name`ok; :name];
  r:.aqc.parse.delim[name`next;"="];
  if[not r`ok; :r];
  e:.aqc.parse.expr r`next;
  if[not e`ok; :e];
  .aqc.parse.ok[.aqc.ast.tuple (name`node;e`node);e`next]};

/ modGroupBy[havingRequired; i]
/   GROUP BY rep1sep(expr, ",") then HAVING rep1sep(expr, "AND"), as in
/   UPDATE (HAVING optional) and DELETE (HAVING required). Unlike SELECT's
/   GROUP BY, the groups are plain expressions with no AS names.
/   The node is (groups; having conditions).
.aqc.parse.modGroupBy:{[havingRequired;i]
  r:.aqc.parse.kws[i;`GROUP`BY];
  if[not r`ok; :r];
  groups:.aqc.parse.sepBy1[.aqc.parse.expr;.aqc.parse.comma;r`next];
  if[not groups`ok; :groups];
  j:groups`next;
  having:();
  r:.aqc.parse.kw[j;`HAVING];
  if[r`ok;
    r:.aqc.parse.sepBy1[.aqc.parse.expr;.aqc.parse.upperAnd;r`next];
    if[r`ok; having:r`node; j:r`next]];
  if[havingRequired and not r`ok; :r];
  .aqc.parse.ok[(groups`node;having);j]};

/ Scala: delete = DELETE FROM ident (ASSUMING order)? (WHERE where)?
/                 (GROUP BY rep1sep(expr, ",") HAVING rep1sep(expr, "AND"))?
/                     -> Delete(table, Right(where), order, group by, having)
/               | DELETE rep1sep(id, ",") FROM ident
/                     -> Delete(table, Left(columns), [], [], [])
/ The first form deletes rows, the second deletes columns.
.aqc.parse.deleteStmt:{[i]
  .aqc.parse.positioned[i;.aqc.parse.firstOf[(.aqc.parse.deleteRows;.aqc.parse.deleteColumns);i]]};

/ DELETE FROM t ...: delete rows
.aqc.parse.deleteRows:{[i]
  r:.aqc.parse.kws[i;`DELETE`FROM];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  j:name`next;
  order:();
  r:.aqc.parse.assumingClause j;
  if[r`ok; order:r`node; j:r`next];
  conds:();
  r:.aqc.parse.whereClauseKw j;
  if[r`ok; conds:r`node; j:r`next];
  groups:();
  having:();
  r:.aqc.parse.modGroupBy[1b;j];
  if[r`ok; groups:r[`node] 0; having:r[`node] 1; j:r`next];
  .aqc.parse.ok[.aqc.ast.deleteStmt[name`node;.aqc.ast.right conds;order;groups;having];j]};

/ DELETE a, b FROM t: delete columns
.aqc.parse.deleteColumns:{[i]
  r:.aqc.parse.kw[i;`DELETE];
  if[not r`ok; :r];
  ids:.aqc.parse.sepBy1[.aqc.parse.id;.aqc.parse.comma;r`next];
  if[not ids`ok; :ids];
  r:.aqc.parse.kw[ids`next;`FROM];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  .aqc.parse.ok[.aqc.ast.deleteStmt[name`node;.aqc.ast.left ids`node;();();()];name`next]};


/ ---- Triggers ---------------------------------------------------------------

/ Scala: trigger = CREATE TRIGGER ident triggerTime triggerEvent ON ident
/                  triggerRefs? DO triggerBody
/   -> Trigger(name, time, event, table, refs, body)
/     CREATE TRIGGER tr AFTER INSERT ON t DO INSERT INTO log VALUES (1)
.aqc.parse.trigger:{[i]
  r:.aqc.parse.kws[i;`CREATE`TRIGGER];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  time:.aqc.parse.triggerTime name`next;
  if[not time`ok; :time];
  event:.aqc.parse.triggerEvent time`next;
  if[not event`ok; :event];
  r:.aqc.parse.kw[event`next;`ON];
  if[not r`ok; :r];
  tbl:.aqc.parse.ident r`next;
  if[not tbl`ok; :tbl];
  j:tbl`next;
  refs:();
  r:.aqc.parse.triggerRefs j;
  if[r`ok; refs:r`node; j:r`next];
  r:.aqc.parse.kw[j;`DO];
  if[not r`ok; :r];
  body:.aqc.parse.triggerBody r`next;
  if[not body`ok; :body];
  tree:.aqc.ast.trigger[name`node;time`node;event`node;tbl`node;refs;body`node];
  .aqc.parse.positioned[i;.aqc.parse.ok[tree;body`next]]};

/ Scala: triggerTime = BEFORE | AFTER   -> `Before or `After
.aqc.parse.triggerTime:{[i] .aqc.parse.pick[i;`BEFORE`AFTER!`Before`After]};

/ Scala: triggerEvent = INSERT | UPDATE | DELETE   -> `InsertEvent, ...
.aqc.parse.triggerEvent:{[i]
  .aqc.parse.pick[i;`INSERT`UPDATE`DELETE!`InsertEvent`UpdateEvent`DeleteEvent]};

/ Scala: triggerRefs = REFERENCING rep1(triggerRef)
.aqc.parse.triggerRefs:{[i]
  r:.aqc.parse.kw[i;`REFERENCING];
  if[not r`ok; :r];
  .aqc.parse.many1[.aqc.parse.triggerRef;r`next]};

/ Scala: triggerRef = NEW TABLE AS ident | OLD TABLE AS ident
/   -> TriggerRef(NewTableRef or OldTableRef, alias)
.aqc.parse.triggerRef:{[i]
  kind:`NewTableRef;
  r:.aqc.parse.kws[i;`NEW`TABLE`AS];
  if[not r`ok;
    kind:`OldTableRef;
    r:.aqc.parse.kws[i;`OLD`TABLE`AS];
    if[not r`ok; :r]];
  alias:.aqc.parse.ident r`next;
  if[not alias`ok; :alias];
  .aqc.parse.ok[.aqc.ast.triggerRef[kind;alias`node];alias`next]};

/ Scala: triggerBody = update | delete | insert | fullQuery
.aqc.parse.triggerBody:{[i]
  .aqc.parse.firstOf[(.aqc.parse.updateStmt;.aqc.parse.deleteStmt;.aqc.parse.insertStmt;.aqc.parse.fullQuery);i]};

/ Scala: dropTrigger = DROP TRIGGER ident   -> DropTrigger(name)
.aqc.parse.dropTrigger:{[i]
  r:.aqc.parse.kws[i;`DROP`TRIGGER];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.dropTrigger name`node;name`next]]};


/ ---- LOAD and SAVE ----------------------------------------------------------

/ Scala: io = LOAD DATA INFILE stringLit INTO TABLE ident
/             FIELDS TERMINATED BY stringLit          -> Load(file, table, sep)
/           | fullQuery INTO OUTFILE stringLit
/             FIELDS TERMINATED BY stringLit          -> Save(file, query, sep)
.aqc.parse.io:{[i]
  .aqc.parse.positioned[i;.aqc.parse.firstOf[(.aqc.parse.loadData;.aqc.parse.saveQuery);i]]};

/ LOAD DATA INFILE "f.csv" INTO TABLE t FIELDS TERMINATED BY ","
.aqc.parse.loadData:{[i]
  r:.aqc.parse.kws[i;`LOAD`DATA`INFILE];
  if[not r`ok; :r];
  file:.aqc.parse.stringLit r`next;
  if[not file`ok; :file];
  r:.aqc.parse.kws[file`next;`INTO`TABLE];
  if[not r`ok; :r];
  tbl:.aqc.parse.ident r`next;
  if[not tbl`ok; :tbl];
  sep:.aqc.parse.fieldsTerminatedBy tbl`next;
  if[not sep`ok; :sep];
  .aqc.parse.ok[.aqc.ast.loadStmt[file`node;tbl`node;sep`node];sep`next]};

/ <query> INTO OUTFILE "out.csv" FIELDS TERMINATED BY ","
.aqc.parse.saveQuery:{[i]
  q:.aqc.parse.fullQuery i;
  if[not q`ok; :q];
  r:.aqc.parse.kws[q`next;`INTO`OUTFILE];
  if[not r`ok; :r];
  file:.aqc.parse.stringLit r`next;
  if[not file`ok; :file];
  sep:.aqc.parse.fieldsTerminatedBy file`next;
  if[not sep`ok; :sep];
  .aqc.parse.ok[.aqc.ast.saveStmt[file`node;q`node;sep`node];sep`next]};

/ FIELDS TERMINATED BY "sep"   (the node is the separator string)
.aqc.parse.fieldsTerminatedBy:{[i]
  r:.aqc.parse.kws[i;`FIELDS`TERMINATED`BY];
  if[not r`ok; :r];
  .aqc.parse.stringLit r`next};


/ ---- User-defined functions -------------------------------------------------

/ Scala: udf = FUNCTION ident "(" repsep(ident, ",") ")"
/              "{" rep1sep(udfBody, ";") "}"
/   -> UDF(name, arguments, body)
/     FUNCTION f(a, b) { c := a + b; c * 2 }
/ The body is one or more parts separated by ";", with no ";" after the
/ last one.
.aqc.parse.udf:{[i]
  r:.aqc.parse.kw[i;`FUNCTION];
  if[not r`ok; :r];
  name:.aqc.parse.ident r`next;
  if[not name`ok; :name];
  args:.aqc.parse.columnList name`next;
  if[not args`ok; :args];
  body:.aqc.parse.between["{";.aqc.parse.sepBy1[.aqc.parse.udfBody;.aqc.parse.semicolon];"}";args`next];
  if[not body`ok; :body];
  .aqc.parse.positioned[i;.aqc.parse.ok[.aqc.ast.udf[name`node;args`node;body`node];body`next]]};

/ semicolon[i]: the delimiter ";"
.aqc.parse.semicolon:{[i] .aqc.parse.delim[i;enlist ";"]};

/ Scala: udfBody = ident ":=" expr   -> Left(Assign(name, expr))
/                | expr              -> Right(expr)
.aqc.parse.udfBody:{[i]
  name:.aqc.parse.ident i;
  if[name`ok;
    r:.aqc.parse.delim[name`next;":="];
    if[r`ok;
      e:.aqc.parse.expr r`next;
      if[e`ok; :.aqc.parse.ok[.aqc.ast.left .aqc.ast.assign[name`node;e`node];e`next]]]];
  e:.aqc.parse.expr i;
  if[not e`ok; :e];
  .aqc.parse.ok[.aqc.ast.right e`node;e`next]};


/ ---------------------------------------------------------------------------
/ Running a rule on source text
/ ---------------------------------------------------------------------------

/ parseRule[rule; src]
/   PUBLIC. Lex src and parse ALL of it with one grammar rule (Scala:
/   parse(rule, s), which uses phrase(rule)).
/     parseRule[.aqc.parse.expr; "1 + x"]   is   `ok`node!(1b; <the tree>)
/     parseRule[.aqc.parse.expr; "1 +"]     is   `ok`msg`line`col!(0b; "end of input"; 1; 4)
/   If the rule matches but tokens are left over, the error is the
/   furthest failure if it is at or after the leftover tokens, else
/   "end of input expected" there (Scala's phrase does the same).
.aqc.parse.parseRule:{[rule;src]
  .aqc.parse.toks:.aqc.lex.tokens src;
  .aqc.parse.furthest:`ok`msg`at!(0b;"";-1);
  r:rule 0;
  if[r`ok;
    if[.aqc.parse.atEnd r`next; :`ok`node!(1b;r`node)];
    if[(.aqc.parse.furthest`at) < r`next; .aqc.parse.furthest:`ok`msg`at!(0b;"end of input expected";r`next)]];
  failure:.aqc.parse.furthest;
  pos:.aqc.parse.posAt failure`at;
  `ok`msg`line`col!(0b;failure`msg;pos 0;pos 1)};

/ showRule[rule; src]
/   PUBLIC, for tests. parseRule, then one line: the tree as Scala prints
/   it, or "FAILURE line:col" (tools/RuleDump.java prints the same).
/     showRule[.aqc.parse.expr; "1 + x"]   is "BinExpr(Plus,IntLit(1),Id(x))"
/     showRule[.aqc.parse.expr; "1 +"]     is "FAILURE 1:4"
.aqc.parse.showRule:{[rule;src]
  r:.aqc.parse.parseRule[rule;src];
  $[r`ok; .aqc.ast.show r`node; "FAILURE ",(string r`line),":",string r`col]};

/ parseFile[path]
/   PUBLIC. Parse the AQuery program in file path and give the lines of the
/   golden-file format (tests/parser/README.md): the tree, or one line
/   "FAILURE<TAB>line:col<TAB>message".
/     bin/l_m64 aquery.q -parse file.a   prints these lines
.aqc.parse.parseFile:{[path]
  r:.aqc.parse.parseRule[.aqc.parse.program;.aqc.util.readFile path];
  if[r`ok; :.aqc.ast.format[0;"";r`node]];
  enlist "FAILURE\t",(string r`line),":",(string r`col),"\t",.aqc.ast.escape r`msg};
