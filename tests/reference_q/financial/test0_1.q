// Translation begins here
.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startYear10);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `startYear10; (*; 365; 10))));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 Target:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[Target;"Target";0b];
 aq__t1:.aq.sort[aq__t1;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t1))];
 aq__t1:?[aq__t1;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 aq__t1
 };
.aq.q0[]
