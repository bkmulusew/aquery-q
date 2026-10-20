// Translation begins here
.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[lineitem;"L";1b];
 aq__t1:.aq.initTable[orders;"O";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;enlist ((=; {x^.aq.cd x} `L.l_orderkey; {x^.aq.cd x} `O.o_orderkey));0b;()];
 aq__t2:?[aq__t2;();0b;((`t.l_orderkey);(`t.l_partkey);(`t.o_orderdate);(`t.o_orderstatus))!({x^.aq.cd x} `L.l_orderkey;{x^.aq.cd x} `L.l_partkey;{x^.aq.cd x} `O.o_orderdate;{x^.aq.cd x} `O.o_orderstatus)];
 aq__t2
 };
.aq.q0[]
