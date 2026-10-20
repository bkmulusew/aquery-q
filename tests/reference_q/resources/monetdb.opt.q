// Translation begins here
// verbatim code

nums:([]val:(`int$1e6)?100.00);
s_asc:asc;


naive_quantile:{[v;pct]
  sorted_v:eval (s_asc;.aq.funEnlist v);
  n:eval (.aq.count;.aq.funEnlist v);
  ix:eval (-; (%; (*; .aq.funEnlist pct; .aq.funEnlist n); 100); 0.5);
  i:eval (floor;.aq.funEnlist ix);
  q_v:eval (sorted_v;.aq.funEnlist i);
  f:eval (-; .aq.funEnlist ix; .aq.funEnlist i);
  extra:eval (.aq.cond; ();(enlist;(enlist;(<>; .aq.funEnlist f; 0); (-; (*; .aq.funEnlist f; (sorted_v;(+; .aq.funEnlist i; 1))); (*; .aq.funEnlist f; (sorted_v;.aq.funEnlist i))))); 0.0);
 eval (.aq.list;(enlist;(+; .aq.funEnlist extra; .aq.funEnlist q_v)))
 };

.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[nums;"nums";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`q95]!enlist (naive_quantile;{x^.aq.cd x} `val;95))];
 aq__t0
 };
.aq.q0[]

.aq.q1:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[nums;"nums";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`q5]!enlist (naive_quantile;{x^.aq.cd x} `val;5))];
 aq__t0
 };
.aq.q1[]
