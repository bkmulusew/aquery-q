// Translation begins here
.aq.show `lineitemdenormalized set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[lineitem;"L";1b];
 aq__t1:.aq.initTable[supplier;"S";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;enlist ((=; {x^.aq.cd x} `L.l_suppkey; {x^.aq.cd x} `S.s_suppkey));0b;()];
 aq__t3:.aq.initTable[nation;"N";1b];
 aq__t4:aq__t2 cross aq__t3;
 aq__t4:?[aq__t4;enlist ((=; {x^.aq.cd x} `S.s_nationkey; {x^.aq.cd x} `N.n_nationkey));0b;()];
 aq__t5:.aq.initTable[region;"R";1b];
 aq__t6:aq__t4 cross aq__t5;
 aq__t6:?[aq__t6;enlist ((=; {x^.aq.cd x} `N.n_regionkey; {x^.aq.cd x} `R.r_regionkey));0b;()];
 aq__t6:?[aq__t6;();0b;((`t.l_orderkey);(`t.l_partkey);(`t.l_suppkey);(`t.l_linenumber);(`t.l_quantity);(`t.l_extendedprice);(`t.l_discount);(`t.l_tax);(`t.l_returnflag);(`t.l_linestatus);(`t.l_shipdate);(`t.l_commitdate);(`t.l_receiptdate);(`t.l_shipinstruct);(`t.l_shipmode);(`t.l_comment);(`r_region))!({x^.aq.cd x} `L.l_orderkey;{x^.aq.cd x} `L.l_partkey;{x^.aq.cd x} `L.l_suppkey;{x^.aq.cd x} `L.l_linenumber;{x^.aq.cd x} `L.l_quantity;{x^.aq.cd x} `L.l_extendedprice;{x^.aq.cd x} `L.l_discount;{x^.aq.cd x} `L.l_tax;{x^.aq.cd x} `L.l_returnflag;{x^.aq.cd x} `L.l_linestatus;{x^.aq.cd x} `L.l_shipdate;{x^.aq.cd x} `L.l_commitdate;{x^.aq.cd x} `L.l_receiptdate;{x^.aq.cd x} `L.l_shipinstruct;{x^.aq.cd x} `L.l_shipmode;{x^.aq.cd x} `L.l_comment;{x^.aq.cd x} `R.r_name)];
 aq__t6
 }[];
