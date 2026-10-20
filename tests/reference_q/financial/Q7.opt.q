// Translation begins here
executeStrategy:{[alloc;mavgday;mavgmonth;px]
  buySignal:eval (>; .aq.funEnlist mavgday; .aq.funEnlist mavgmonth);
 eval (*; .aq.funEnlist alloc; (.aq.prd;(.aq.cond; (.aq.maxs1;.aq.funEnlist buySignal);(enlist;(enlist;1b; (.aq.cond; .aq.funEnlist buySignal;(enlist;(enlist;1b; (%; 1; .aq.funEnlist px))); .aq.funEnlist px))); 1)))
 };

.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;enlist ((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10));0b;()];
 aq__t0:?[aq__t0;enlist ((>=; {x^.aq.cd x} `TradeDate; (-; (.aq.max;{x^.aq.cd x} `TradeDate); 365)));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 pxdata:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;enlist ((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10));0b;()];
 aq__t1:?[aq__t1;enlist ((>=; {x^.aq.cd x} `SplitDate; (-; (.aq.max;{x^.aq.cd x} `SplitDate); 365)));0b;()];
 aq__t1:?[aq__t1;();0b;((`Id);(`SplitDate);(`SplitFactor))!({x^.aq.cd x} `Id;{x^.aq.cd x} `SplitDate;{x^.aq.cd x} `SplitFactor)];
 splitdata:`Id`SplitDate`SplitFactor xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[pxdata;"pxdata";1b];
 aq__t3:.aq.initTable[splitdata;"splitdata";1b];
 aq__t4:.aq.joinUsing[.aq.ej;aq__t2;aq__t3;enlist ({x^.aq.cd x} `Id)];
 aq__t4:?[aq__t4;enlist ((<; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `SplitDate));0b;()];
 aq__t4:?[aq__t4;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `TradeDate))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate);({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate) _ (.aq.wildCard aq__t4)];
 aq__t4:?[aq__t4;();0b;((`Id);(`TradeDate);(`c__0))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(.aq.first1';(*; {x^.aq.cd x} `ClosePrice; (.aq.prd';{x^.aq.cd x} `SplitFactor))))];
 splitadj:`Id`TradeDate`ClosePrice xcol aq__t4;
 .aq.initQueryState[];
 aq__t5:.aq.initTable[pxdata;"pxdata";1b];
 aq__t6:.aq.initTable[splitadj;"splitadj";1b];
 aq__t7:.aq.joinUsing[.aq.foju;aq__t5;aq__t6;({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate)];
 aq__t7:?[aq__t7;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(.aq.fill;{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice))];
 adjpxdata:`Id`TradeDate`ClosePrice xcol aq__t7;
 .aq.initQueryState[];
 aq__t8:.aq.initTable[adjpxdata;"adjpxdata";0b];
 aq__t8:?[aq__t8;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t8)];
 aq__t8:.aq.sortGrouped[aq__t8;enlist ((iasc;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 aq__t8:?[aq__t8;();0b;((`Id);(`TradeDate);(`ClosePrice);(`c__0);(`c__1))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice;(.aq.avgs2';21;{x^.aq.cd x} `ClosePrice);(.aq.avgs2';160;{x^.aq.cd x} `ClosePrice))];
 movingAvgs:`Id`TradeDate`ClosePrice`m21day`m5month xcol aq__t8;
 .aq.initQueryState[];
 aq__t9:.aq.initTable[eval (.aq.flatten;movingAvgs);"";0b];
 aq__t9:?[aq__t9;enlist ((=; {x^.aq.cd x} `Id; (.aq.prev1;{x^.aq.cd x} `Id)));0b;()];
 aq__t9:?[aq__t9;enlist ((.aq.or;(enlist;(&; (<=; (.aq.prev1;{x^.aq.cd x} `m5month); (.aq.prev1;{x^.aq.cd x} `m21day)); (>; {x^.aq.cd x} `m5month; {x^.aq.cd x} `m21day));(&; (>=; (.aq.prev1;{x^.aq.cd x} `m5month); (.aq.prev1;{x^.aq.cd x} `m21day)); (<; {x^.aq.cd x} `m5month; {x^.aq.cd x} `m21day)))));0b;()];
 aq__t9:?[aq__t9;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t9)];
 aq__t9:?[aq__t9;();0b;((`Id);(`c__0);(`c__1))!({x^.aq.cd x} `Id;(executeStrategy';10000;{x^.aq.cd x} `m21day;{x^.aq.cd x} `m5month;{x^.aq.cd x} `ClosePrice);(>; (.aq.last1';{x^.aq.cd x} `m21day); (.aq.last1';{x^.aq.cd x} `m5month)))];
 simulated:`Id`result`stillInvested xcol aq__t9;
 .aq.initQueryState[];
 aq__t10:.aq.initTable[adjpxdata;"adjpxdata";0b];
 aq__t10:?[aq__t10;enlist ((=; {x^.aq.cd x} `TradeDate; (.aq.max;{x^.aq.cd x} `TradeDate)));0b;()];
 aq__t10:?[aq__t10;();0b;(.aq.wildCard aq__t10)];
 latestPxs:aq__t10;
 .aq.initQueryState[];
 aq__t11:.aq.initTable[latestPxs;"latestPxs";1b];
 aq__t12:.aq.initTable[simulated;"simulated";1b];
 aq__t13:.aq.joinUsing[.aq.foju;aq__t11;aq__t12;enlist ({x^.aq.cd x} `Id)];
 aq__t13:?[aq__t13;();0b;(enlist[`stock_value]!enlist (.aq.sum;(.aq.fill;10000;(*; {x^.aq.cd x} `result; (.aq.cond; ();(enlist;(enlist;{x^.aq.cd x} `stillInvested; {x^.aq.cd x} `ClosePrice)); 1)))))];
 aq__t13
 };
.aq.q0[]
