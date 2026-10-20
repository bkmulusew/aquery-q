/ keywords.q - the AQuery keywords (reserved words).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryParser.scala:
/   the `protected val XXX = Keyword("XXX")` lines (102 keywords; those
/   written `fun = true` are also built-in functions) and `alwaysUpperCase`.


/ The 32 keywords that are also built-in functions (Scala: fun = true).
/ The lexer does not care; the parser will.
.aqc.kw.functions:`ABS`AVG`AVGS`CONCATENATE`COUNT`DELTAS`DISTINCT`DROP`FILL`FILLS,
  `FIRST`FLATTEN`LAST`LIST`MAX`MAXS`MIN`MINS`MOVING`NEXT`NOT`OR`PREV`PRD`PRDS,
  `REVERSE`SHOW`SQRT`STDDEV`SUM`SUMS`VARS;

/ The other 70 keywords.
.aqc.kw.others:`ALL`AND`ARRAYS`AS`ASSUMING`ASC`AFTER`BETWEEN`BEFORE`BOOLEAN`BY`CASE,
  `CREATE`DATA`DATE`DELETE`DESC`DO`ELSE`END`EVEN`EVERY`EXCEPT`EXEC`EXISTS`FALSE,
  `FIELDS`FLOAT`FROM`FULL`FUNCTION`GROUP`HAVING`IF`IN`INFILE`INNER`INSERT`INT`INTO,
  `IS`JOIN`LIKE`LOAD`NEW`NULL`ODD`OLD`ON`OUTER`OUTFILE`OVERLAPS`REFERENCING`ROWID,
  `SAVE`SET`SELECT`STRING`TABLE`TERMINATED`THEN`TIMESTAMP`TRUE`TRIGGER`UPDATE,
  `USING`VALUES`WITH`WHEN`WHERE;

/ One row per keyword, in alphabetical order:
/   word        isFunction
/   `ABS        1b
/   `AFTER      0b  ...
.aqc.kw.table:([] word:asc .aqc.kw.functions,.aqc.kw.others);
.aqc.kw.table:update isFunction:word in .aqc.kw.functions from .aqc.kw.table;

/ Keywords that count only when written in capitals, so that e.g. `date`
/ and `int` can still be used as column names.
.aqc.kw.alwaysUpper:`TIMESTAMP`INT`FLOAT`STRING`BOOLEAN`DATE;

/ Every exact spelling that lexes as a Keyword (Scala: Keyword.canonical):
/ each keyword in capitals, plus in lower case unless it is alwaysUpper.
/ `SELECT and `select are reserved; `Select is not, so it is an Identifier.
/ 102 upper-case + 96 lower-case = 198 symbols.
.aqc.kw.reserved:(.aqc.kw.table`word),`$lower string (.aqc.kw.table`word) except .aqc.kw.alwaysUpper;


/ isReserved[word]
/   Is this exact spelling a keyword?
/     isReserved "select"   is 1b
/     isReserved "Select"   is 0b
/   word:    string
/   returns: boolean
.aqc.kw.isReserved:{[word] (`$word) in .aqc.kw.reserved};
