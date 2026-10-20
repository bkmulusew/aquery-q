// Translation begins here
add:{[x;y]
 eval (+; .aq.funEnlist x; .aq.funEnlist y)
 };

myAvg:{[x]
 eval (%; (.aq.sum;.aq.funEnlist x); (.aq.count;.aq.funEnlist x))
 };

.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[some_t;"some_t";0b];
 aq__t0:.aq.sort[aq__t0;((iasc;{x^.aq.cd x} `c2);(iasc;{x^.aq.cd x} `c1));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;((>; {x^.aq.cd x} `c2; 2);(>; (.aq.sums1;{x^.aq.cd x} `c6); 2));0b;()];
 aq__t0:?[aq__t0;();(enlist[{x^.aq.cd x} `c2]!enlist {x^.aq.cd x} `c2);({x^.aq.cd x} `c2) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`c1);(`c2);(`c__0);(`myCol))!({x^.aq.cd x} `c1;{x^.aq.cd x} `c2;(.aq.sum';(*; {x^.aq.cd x} `c3; (.aq.maxs1';{x^.aq.cd x} `c0)));(.aq.sum';{x^.aq.cd x} `c8))];
 temp1:aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[temp1;"temp1";1b];
 aq__t2:.aq.initTable[t;"t";1b];
 aq__t3:.aq.joinUsing[.aq.ej;aq__t1;aq__t2;enlist ({x^.aq.cd x} `c1)];
 aq__t3:.aq.sort[aq__t3;((iasc;{x^.aq.cd x} `c1);(iasc;{x^.aq.cd x} `t.c2));((.aq.wildCard aq__t3))];
 aq__t3:?[aq__t3;((>; {x^.aq.cd x} `t.c3; 2);(>; {x^.aq.cd x} `temp1.c0; 2);(>; (add;{x^.aq.cd x} `t.c1;{x^.aq.cd x} `c4); 2));0b;()];
 aq__t3:?[aq__t3;();(enlist[{x^.aq.cd x} `c1]!enlist {x^.aq.cd x} `c1);({x^.aq.cd x} `c1) _ (.aq.wildCard aq__t3)];
 aq__t3:?[aq__t3;();0b;((`c1);(`c__0);(`c__1))!({x^.aq.cd x} `c1;(add';{x^.aq.cd x} `c2;{x^.aq.cd x} `myCol);(myAvg';{x^.aq.cd x} `c0))];
 aq__t3
 };
.aq.q0[]
