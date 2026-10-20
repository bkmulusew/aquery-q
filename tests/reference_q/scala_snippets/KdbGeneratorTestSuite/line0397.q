// Translation begins here
// verbatim code
 base:([]c1:1000?100; c2:1000?100; c3:1000?100); 

.aq.show `upd_t set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[base;"base";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

.aq.show `del_t set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[base;"base";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[upd_t;"upd_t";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `c1));((.aq.wildCard aq__t0))];
 
 .aq.update[`upd_t;aq__t0;();0b;(({x^.aq.cd x} `c1);({x^.aq.cd x} `c3))!((*; {x^.aq.cd x} `c1; 2);(.aq.cond; ();(enlist;(enlist;(>; {x^.aq.cd x} `c3; 50); 1)); -1))]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[del_t;"del_t";0b];
 
 .aq.initQueryState[];
 aq__t1:.aq.initTable[aq__t0;"aq__t0";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1),(enlist[`aq__ix]!enlist `i)];
 aq__t1:?[aq__t1;();0b;()];
 aq__t1:?[aq__t1;();(enlist[{x^.aq.cd x} `c1]!enlist {x^.aq.cd x} `c1);({x^.aq.cd x} `c1) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;((>; (.aq.count';{x^.aq.cd x} `c2); 4);(any';(>; {x^.aq.cd x} `c3; 2)));0b;()];
  aq__ix:@[(count aq__t0)#0b;(ungroup 0!aq__t1)`aq__ix;:;1b];

 .aq.deleteRows[`del_t;aq__t0;enlist aq__ix]
 }[];

// verbatim code
.aq.c1:{upd_t}; .aq.c2:{del_t};
