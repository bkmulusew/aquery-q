// Translation begins here
// verbatim code
 base:([]c1:1000?100; c2:1000?100; c3:1000?100) 

.aq.show `aq_t1 set ([]c1:"j"$();c2:"s"$();c3:"b"$());

.aq.show `aq_t2 set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[base;"base";0b];
 aq__t0:?[aq__t0;enlist ((>; {x^.aq.cd x} `c1; 10));0b;()];
 aq__t0:?[aq__t0;();(enlist[{x^.aq.cd x} `c1]!enlist {x^.aq.cd x} `c1);({x^.aq.cd x} `c1) _ (.aq.wildCard aq__t0)];
 aq__t0:.aq.sortGrouped[aq__t0;enlist ((iasc;{x^.aq.cd x} `c3));({x^.aq.cd x} `c1;{x^.aq.cd x} `c2)];
 aq__t0:?[aq__t0;();0b;((`c1);(`c2);(`max_c3))!((*; {x^.aq.cd x} `c1; 2);(.aq.sums1';{x^.aq.cd x} `c2);(.aq.max';{x^.aq.cd x} `c3))];
 aq__t0
 }[];

// verbatim code
.aq.c1:{aq_t1}; .aq.c2:{aq_t2};
