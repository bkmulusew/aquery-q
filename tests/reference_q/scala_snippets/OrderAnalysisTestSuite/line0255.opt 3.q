// Translation begins here
.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";1b];
 aq__t1:.aq.initTable[t1;"t1";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t3:.aq.initTable[t2;"t2";1b];
 aq__t4:.aq.joinUsing[.aq.ej;aq__t2;aq__t3;enlist ({x^.aq.cd x} `c1)];
 aq__t4:?[aq__t4;enlist ((>; {x^.aq.cd x} `c1; 2));0b;()];
 aq__t4:.aq.sort[aq__t4;((iasc;{x^.aq.cd x} `c1);(idesc;{x^.aq.cd x} `t.c2));((.aq.wildCard aq__t4))];
 aq__t4:?[aq__t4;();0b;(.aq.wildCard aq__t4)];
 aq__t4
 };
.aq.q0[]
