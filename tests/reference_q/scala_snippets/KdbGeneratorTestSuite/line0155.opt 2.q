// Translation begins here
// verbatim code
 base:([]c2:1 2 3 4; c3:100 200 300 400) 

.aq.show `t set ([]c1:"j"$();c2:"j"$();c3:"s"$());

.aq.insert[`t;t;();eval (enlist;1;2;`$"c")]

.aq.insert[`t;t;();eval (enlist;10;20;`$"C")]

.aq.insert[`t;t;`c1`c2`c3;
 {
  .aq.initQueryState[];
 aq__t0:.aq.initTable[base;"base";0b];
 aq__t0:?[aq__t0;();0b;((`c2);(`c2);(`c__0))!({x^.aq.cd x} `c2;{x^.aq.cd x} `c2;`$"this is a test")];
 aq__t0
 }[]]

.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q0[]
