// Translation begins here
// verbatim code

q9StartYear:{getYear maxTradeDateMinus3Years};


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[split;"split";0b];
 aq__t0:?[aq__t0;enlist ((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000));0b;()];
 aq__t0:?[aq__t0;enlist ((>=; (getYear;{x^.aq.cd x} `SplitDate); (q9StartYear;)));0b;()];
 aq__t0:?[aq__t0;();0b;((`c__0);(`c__1))!(1;(.aq.distinct;{x^.aq.cd x} `Id))];
 splitdata:`Dummy`Id xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[splitdata;"splitdata";0b];
 aq__t1:?[aq__t1;();0b;((`Dummy);(`Id))!({x^.aq.cd x} `Dummy;{x^.aq.cd x} `Id)];
 aq__t1
 };
.aq.q0[]
