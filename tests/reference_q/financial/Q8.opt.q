// Translation begins here
covariance:{[x;y]
  xmean:eval (.aq.avg;.aq.funEnlist x);
  ymean:eval (.aq.avg;.aq.funEnlist y);
 eval (.aq.avg;(*; (-; .aq.funEnlist x; .aq.funEnlist xmean); (-; .aq.funEnlist y; .aq.funEnlist ymean)))
 };

sd:{[x]
 eval (.aq.sqrt;(covariance;.aq.funEnlist x;.aq.funEnlist x))
 };

pairCorr:{[x;y]
 eval (%; (covariance;.aq.funEnlist x;.aq.funEnlist y); (*; (sd;.aq.funEnlist x); (sd;.aq.funEnlist y)))
 };

// verbatim code
pairCorrEach:pairCorr'

// verbatim code

/ Original Q8 time window. Restore these predicates if you want the old
/ benchmark range:
/   AND TradeDate >= startYear10
/   AND TradeDate <= startYear10 + 365 * 2


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;.aq.reorderFilter[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startPeriod);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `startPeriod; 3)))];0b;()];
 aq__t0:?[aq__t0;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t0)];
 aq__t0:.aq.sortGrouped[aq__t0;enlist ((iasc;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `ClosePrice)];
 aq__t0:?[aq__t0;();0b;((`Id);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `ClosePrice)];
 stocksGrouped:`Id`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[stocksGrouped;"st1";1b];
 aq__t2:.aq.initTable[stocksGrouped;"st2";1b];
 aq__t3:aq__t1 cross aq__t2;
 aq__t3:?[aq__t3;();0b;((`t.Id);(`t.Id);(`t.ClosePrice);(`t.ClosePrice))!({x^.aq.cd x} `st1.Id;{x^.aq.cd x} `st2.Id;{x^.aq.cd x} `st1.ClosePrice;{x^.aq.cd x} `st2.ClosePrice)];
 pairsGrouped:`Id1`Id2`ClosePrice1`ClosePrice2 xcol aq__t3;
 .aq.initQueryState[];
 aq__t4:.aq.initTable[pairsGrouped;"pairsGrouped";0b];
 aq__t4:?[aq__t4;enlist ((<>; {x^.aq.cd x} `Id1; {x^.aq.cd x} `Id2));0b;()];
 aq__t4:?[aq__t4;();0b;((`Id1);(`Id2);(`c__0))!({x^.aq.cd x} `Id1;{x^.aq.cd x} `Id2;(pairCorrEach;{x^.aq.cd x} `ClosePrice1;{x^.aq.cd x} `ClosePrice2))];
 corrTable:`Id1`Id2`corrCoeff xcol aq__t4;
 .aq.initQueryState[];
 aq__t5:.aq.initTable[corrTable;"corrTable";0b];
 aq__t5:.aq.sort[aq__t5;enlist ((iasc;{x^.aq.cd x} `corrCoeff));((.aq.wildCard aq__t5))];
 aq__t5:?[aq__t5;();0b;(.aq.wildCard aq__t5)];
 aq__t5
 };
.aq.q0[]
