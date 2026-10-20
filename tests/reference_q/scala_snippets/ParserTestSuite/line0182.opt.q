// Translation begins here
{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `c1));((.aq.wildCard aq__t0))];
 
 .aq.initQueryState[];
 aq__t1:.aq.initTable[aq__t0;"aq__t0";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1),(enlist[`aq__ix]!enlist `i)];
 aq__t1:?[aq__t1;enlist ((>; (.aq.sums1;{x^.aq.cd x} `c); 100));0b;()];
 aq__t1:?[aq__t1;();(enlist[{x^.aq.cd x} `a]!enlist {x^.aq.cd x} `a);({x^.aq.cd x} `a) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;enlist ((>; (.aq.max';{x^.aq.cd x} `d); 20));0b;()];
  aq__ix:@[(count aq__t0)#0b;(ungroup 0!aq__t1)`aq__ix;:;1b];

 .aq.deleteRows[`t;aq__t0;enlist aq__ix]
 }[];
