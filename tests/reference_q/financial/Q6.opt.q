// Translation begins here
.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;.aq.reorderFilter[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `start6Mo);(<; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `start6Mo; (*; 31; 6))))];0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 pxdata:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;.aq.reorderFilter[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `SplitDate; {x^.aq.cd x} `start6Mo))];0b;()];
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
 aq__t7:?[aq__t7;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t7)];
 aq__t7:.aq.sortGrouped[aq__t7;enlist ((iasc;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice)];
 aq__t7:?[aq__t7;();0b;((`Id);(`TradeDate);(`c__0);(`c__1);(`c__2))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice);(.aq.avgs2';21;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice));(.aq.avgs2';5;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice)))];
 avgInfo:`Id`TradeDate`ClosePrice`m21`m5 xcol aq__t7;
 .aq.initQueryState[];
 aq__t8:.aq.initTable[eval (.aq.flatten;avgInfo);"";0b];
 aq__t8:?[aq__t8;enlist ((=; {x^.aq.cd x} `Id; (.aq.prev1;{x^.aq.cd x} `Id)));0b;()];
 aq__t8:?[aq__t8;enlist ((.aq.or;(enlist;(&; (<=; (.aq.prev1;{x^.aq.cd x} `m5); (.aq.prev1;{x^.aq.cd x} `m21)); (>; {x^.aq.cd x} `m5; {x^.aq.cd x} `m21));(&; (>=; (.aq.prev1;{x^.aq.cd x} `m5); (.aq.prev1;{x^.aq.cd x} `m21)); (<; {x^.aq.cd x} `m5; {x^.aq.cd x} `m21)))));0b;()];
 aq__t8:?[aq__t8;();0b;((`Id);(`CrossDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 aq__t8
 };
.aq.q0[]
