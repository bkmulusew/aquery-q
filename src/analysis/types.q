/ types.q - the type tags of the type checker (version 6).

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/analysis/AnalysisTypes.scala.

/ The checker is "soft": it only knows the type of literals, operators and
/ built-in function results. A column or variable is always `unknown, and
/ `unknown matches every type, so a check only fails when both types are
/ known and differ.

/ The 6 type tags, as q symbols. Scala's names are TNumeric, TBoolean, ...;
/ the symbols are the words Scala prints in error messages.
/   `numeric   ints, floats, dates and timestamps
/   `boolean
/   `string
/   `unit      "no value" (SHOW returns it; a CASE with no WHEN reports it)
/   `table     declared by Scala but never produced
/   `unknown   anything whose type is only known when q runs it
.aqc.tc.tags:`numeric`boolean`string`unit`table`unknown;

/ The sets of tags Scala names (AnalysisTypes.bool, num, numAndBool).
/ A set is a symbol list.
.aqc.tc.bool:enlist `boolean;
.aqc.tc.num:enlist `numeric;
.aqc.tc.numAndBool:`numeric`boolean;


/ consistent[t; s]
/   Is type t allowed where one of the types in s is expected? Yes when t
/   is in s, or when either side is `unknown.
/     consistent[`numeric; `numeric`boolean]   is 1b
/     consistent[`string; enlist `numeric]     is 0b
/     consistent[`unknown; enlist `numeric]    is 1b
/     consistent[`string; enlist `unknown]     is 1b
/   t: a type tag;  s: a symbol list of type tags
/   (Scala: TypeTag.consistent)
.aqc.tc.consistent:{[t;s] (t = `unknown) or (t in s) or `unknown in s};

/ allConsistent[ts; s]
/   Is every type in ts consistent with s? 1b when ts is empty.
/     allConsistent[`numeric`unknown; enlist `numeric]   is 1b
/   (Scala: ts.forall(_.consistent(s)))
.aqc.tc.allConsistent:{[ts;s] all {[s;t] .aqc.tc.consistent[t;s]}[s] each ts};
