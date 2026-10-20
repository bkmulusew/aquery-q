// Translation begins here
// verbatim code
aqConstWeekly:{(count x)#`weekly};
aqConstMonthly:{(count x)#`monthly};
aqConstYearly:{(count x)#`yearly};

.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startYear10);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `startYear10; (*; 365; 10))));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 Target:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[Target;"Target";0b];
 aq__t1:?[aq__t1;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getWeek;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(aqConstWeekly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 weekly:`Id`bucket`name`low`high`mean xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[Target;"Target";0b];
 aq__t2:?[aq__t2;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getMonth;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t2)];
 aq__t2:?[aq__t2;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(aqConstMonthly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 monthly:`Id`bucket`name`low`high`mean xcol aq__t2;
 .aq.initQueryState[];
 aq__t3:.aq.initTable[Target;"Target";0b];
 aq__t3:?[aq__t3;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t3)];
 aq__t3:?[aq__t3;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(aqConstYearly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 yearly:`Id`bucket`name`low`high`mean xcol aq__t3;
 .aq.initQueryState[];
 aq__t4:.aq.initTable[eval (.aq.concatenate;(enlist;weekly;monthly;yearly));"";0b];
 aq__t4:.aq.sort[aq__t4;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `name);(iasc;{x^.aq.cd x} `bucket));((.aq.wildCard aq__t4))];
 aq__t4:?[aq__t4;();0b;((`Id);(`bucket);(`name);(`low);(`high);(`mean))!({x^.aq.cd x} `Id;{x^.aq.cd x} `bucket;{x^.aq.cd x} `name;{x^.aq.cd x} `low;{x^.aq.cd x} `high;{x^.aq.cd x} `mean)];
 aq__t4
 };
.aq.q0[]

.aq.q1:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `start300Days);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `start300Days; 300)));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`HighPrice);(`LowPrice);(`ClosePrice);(`OpenPrice);(`Volume))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `HighPrice;{x^.aq.cd x} `LowPrice;{x^.aq.cd x} `ClosePrice;{x^.aq.cd x} `OpenPrice;{x^.aq.cd x} `Volume)];
 pxdata:`Id`TradeDate`HighPrice`LowPrice`ClosePrice`OpenPrice`Volume xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `SplitDate; {x^.aq.cd x} `start300Days));0b;()];
 aq__t1:?[aq__t1;();0b;((`Id);(`SplitDate);(`SplitFactor))!({x^.aq.cd x} `Id;{x^.aq.cd x} `SplitDate;{x^.aq.cd x} `SplitFactor)];
 splitdata:`Id`SplitDate`SplitFactor xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[pxdata;"pxdata";1b];
 aq__t3:.aq.initTable[splitdata;"splitdata";1b];
 aq__t4:.aq.joinUsing[.aq.ej;aq__t2;aq__t3;enlist ({x^.aq.cd x} `Id)];
 aq__t4:?[aq__t4;enlist ((<; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `SplitDate));0b;()];
 aq__t4:?[aq__t4;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `TradeDate))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate);({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate) _ (.aq.wildCard aq__t4)];
 aq__t4:?[aq__t4;();0b;((`Id);(`TradeDate);(`c__0))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(.aq.prd';{x^.aq.cd x} `SplitFactor))];
 adjdata:`Id`TradeDate`AdjFactor xcol aq__t4;
 .aq.initQueryState[];
 aq__t5:.aq.initTable[pxdata;"pxdata";1b];
 aq__t6:.aq.initTable[adjdata;"adjdata";1b];
 aq__t7:.aq.joinUsing[.aq.foju;aq__t5;aq__t6;({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate)];
 aq__t7:.aq.sort[aq__t7;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t7))];
 aq__t7:?[aq__t7;();0b;((`Id);(`TradeDate);(`HighPrice);(`LowPrice);(`ClosePrice);(`OpenPrice);(`Volume))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(*; {x^.aq.cd x} `HighPrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(*; {x^.aq.cd x} `LowPrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(*; {x^.aq.cd x} `ClosePrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(*; {x^.aq.cd x} `OpenPrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(%; {x^.aq.cd x} `Volume; (.aq.fill;1;{x^.aq.cd x} `AdjFactor)))];
 aq__t7
 };
.aq.q1[]

.aq.q2:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(.aq.between;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `startPeriod;{x^.aq.cd x} `endPeriod));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`HighPrice);(`LowPrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `HighPrice;{x^.aq.cd x} `LowPrice)];
 pxdata:`Id`TradeDate`HighPrice`LowPrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(.aq.between;{x^.aq.cd x} `SplitDate;{x^.aq.cd x} `startPeriod;{x^.aq.cd x} `endPeriod));0b;()];
 aq__t1:?[aq__t1;();0b;((`Id);(`SplitDate);(`SplitFactor))!({x^.aq.cd x} `Id;{x^.aq.cd x} `SplitDate;{x^.aq.cd x} `SplitFactor)];
 splitdata:`Id`TradeDate`SplitFactor xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[pxdata;"pxdata";1b];
 aq__t3:.aq.initTable[splitdata;"splitdata";1b];
 aq__t4:.aq.joinUsing[.aq.ej;aq__t2;aq__t3;({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate)];
 aq__t4:.aq.sort[aq__t4;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t4))];
 aq__t4:?[aq__t4;();0b;((`Id);(`TradeDate);(`MaxDiff))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(-; {x^.aq.cd x} `HighPrice; {x^.aq.cd x} `LowPrice))];
 aq__t4
 };
.aq.q2[]

.aq.q3:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `SP500);(=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startPeriod));0b;()];
 aq__t0:?[aq__t0;();0b;(enlist[`avg_close_price]!enlist (.aq.avg;{x^.aq.cd x} `ClosePrice))];
 aq__t0
 };
.aq.q3[]

.aq.q4:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startPeriod));0b;()];
 aq__t0:?[aq__t0;();0b;(enlist[`avg_close_price]!enlist (.aq.avg;{x^.aq.cd x} `ClosePrice))];
 aq__t0
 };
.aq.q4[]

.aq.q5:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `start6Mo);(<; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `start6Mo; (*; 31; 6))));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 pxdata:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `SplitDate; {x^.aq.cd x} `start6Mo));0b;()];
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
 aq__t7:.aq.sort[aq__t7;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t7))];
 aq__t7:?[aq__t7;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t7)];
 aq__t7:?[aq__t7;();0b;((`Id);(`TradeDate);(`c__0);(`c__1);(`c__2))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice);(.aq.avgs2';21;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice));(.aq.avgs2';5;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice)))];
 avgInfo:`Id`TradeDate`ClosePrice`m21`m5 xcol aq__t7;
 .aq.initQueryState[];
 aq__t8:.aq.initTable[eval (.aq.flatten;avgInfo);"";0b];
 aq__t8:.aq.sort[aq__t8;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t8))];
 aq__t8:?[aq__t8;();0b;(.aq.wildCard aq__t8)];
 aq__t8
 };
.aq.q5[]

.aq.q6:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `start6Mo);(<; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `start6Mo; (*; 31; 6))));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 pxdata:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `SplitDate; {x^.aq.cd x} `start6Mo));0b;()];
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
 aq__t7:.aq.sort[aq__t7;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t7))];
 aq__t7:?[aq__t7;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t7)];
 aq__t7:?[aq__t7;();0b;((`Id);(`TradeDate);(`c__0);(`c__1);(`c__2))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice);(.aq.avgs2';21;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice));(.aq.avgs2';5;(.aq.fill';{x^.aq.cd x} `pxdata.ClosePrice;{x^.aq.cd x} `splitadj.ClosePrice)))];
 avgInfo:`Id`TradeDate`ClosePrice`m21`m5 xcol aq__t7;
 .aq.initQueryState[];
 aq__t8:.aq.initTable[eval (.aq.flatten;avgInfo);"";0b];
 aq__t8:?[aq__t8;((=; {x^.aq.cd x} `Id; (.aq.prev1;{x^.aq.cd x} `Id));(.aq.or;(enlist;(&; (<=; (.aq.prev1;{x^.aq.cd x} `m5); (.aq.prev1;{x^.aq.cd x} `m21)); (>; {x^.aq.cd x} `m5; {x^.aq.cd x} `m21));(&; (>=; (.aq.prev1;{x^.aq.cd x} `m5); (.aq.prev1;{x^.aq.cd x} `m21)); (<; {x^.aq.cd x} `m5; {x^.aq.cd x} `m21)))));0b;()];
 aq__t8:?[aq__t8;();0b;((`Id);(`CrossDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 aq__t8
 };
.aq.q6[]

executeStrategy:{[alloc;mavgday;mavgmonth;px]
  buySignal:eval (>; .aq.funEnlist mavgday; .aq.funEnlist mavgmonth);
 eval (*; .aq.funEnlist alloc; (.aq.prd;(.aq.cond; (.aq.maxs1;.aq.funEnlist buySignal);(enlist;(enlist;1b; (.aq.cond; .aq.funEnlist buySignal;(enlist;(enlist;1b; (%; 1; .aq.funEnlist px))); .aq.funEnlist px))); 1)))
 };

.aq.q7:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; (-; (.aq.max;{x^.aq.cd x} `TradeDate); 365)));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 pxdata:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `SplitDate; (-; (.aq.max;{x^.aq.cd x} `SplitDate); 365)));0b;()];
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
 aq__t8:.aq.sort[aq__t8;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t8))];
 aq__t8:?[aq__t8;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t8)];
 aq__t8:?[aq__t8;();0b;((`Id);(`TradeDate);(`ClosePrice);(`c__0);(`c__1))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice;(.aq.avgs2';21;{x^.aq.cd x} `ClosePrice);(.aq.avgs2';160;{x^.aq.cd x} `ClosePrice))];
 movingAvgs:`Id`TradeDate`ClosePrice`m21day`m5month xcol aq__t8;
 .aq.initQueryState[];
 aq__t9:.aq.initTable[eval (.aq.flatten;movingAvgs);"";0b];
 aq__t9:?[aq__t9;((=; {x^.aq.cd x} `Id; (.aq.prev1;{x^.aq.cd x} `Id));(.aq.or;(enlist;(&; (<=; (.aq.prev1;{x^.aq.cd x} `m5month); (.aq.prev1;{x^.aq.cd x} `m21day)); (>; {x^.aq.cd x} `m5month; {x^.aq.cd x} `m21day));(&; (>=; (.aq.prev1;{x^.aq.cd x} `m5month); (.aq.prev1;{x^.aq.cd x} `m21day)); (<; {x^.aq.cd x} `m5month; {x^.aq.cd x} `m21day)))));0b;()];
 aq__t9:?[aq__t9;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t9)];
 aq__t9:?[aq__t9;();0b;((`Id);(`result);(`stillInvested))!({x^.aq.cd x} `Id;(executeStrategy';10000;{x^.aq.cd x} `m21day;{x^.aq.cd x} `m5month;{x^.aq.cd x} `ClosePrice);(>; (.aq.last1';{x^.aq.cd x} `m21day); (.aq.last1';{x^.aq.cd x} `m5month)))];
 simulated:aq__t9;
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
.aq.q7[]

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

.aq.q8:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:.aq.sort[aq__t0;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startYear10);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `startYear10; (*; 365; 2))));0b;()];
 aq__t0:?[aq__t0;();(enlist[{x^.aq.cd x} `Id]!enlist {x^.aq.cd x} `Id);({x^.aq.cd x} `Id) _ (.aq.wildCard aq__t0)];
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
.aq.q8[]

.aq.q9:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;();0b;((`c__0);(`c__1))!((getYear;(-; (.aq.max;{x^.aq.cd x} `TradeDate); (*; 365; 3)));(-; (.aq.max;{x^.aq.cd x} `TradeDate); (*; 365; 3)))];
 DateInfo:`startYear`startDate xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(>=; (getYear;{x^.aq.cd x} `SplitDate); (.aq.first1;DateInfo`startYear)));0b;()];
 aq__t1:?[aq__t1;();0b;((`c__0);(`c__1))!(1;(.aq.distinct;{x^.aq.cd x} `Id))];
 splitdata:`Dummy`Id xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[price;"price";0b];
 aq__t2:?[aq__t2;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(>=; {x^.aq.cd x} `TradeDate; (.aq.first1;DateInfo`startDate));(.aq.not;(.aq.in;{x^.aq.cd x} `Id;enlist splitdata`Id)));0b;()];
 aq__t2:?[aq__t2;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `year))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `year) _ (.aq.wildCard aq__t2)];
 aq__t2:?[aq__t2;();0b;((`Id);(`year);(`avg_px))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 nosplit_avgpx:aq__t2;
 .aq.initQueryState[];
 aq__t3:.aq.initTable[dividend;"dividend";0b];
 aq__t3:?[aq__t3;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(>=; (getYear;{x^.aq.cd x} `AnnounceDate); (.aq.first1;DateInfo`startYear));(.aq.not;(.aq.in;{x^.aq.cd x} `Id;enlist splitdata`Id)));0b;()];
 aq__t3:?[aq__t3;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `year))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `AnnounceDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `year) _ (.aq.wildCard aq__t3)];
 aq__t3:?[aq__t3;();0b;((`Id);(`year);(`total_divs))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;(.aq.sum';{x^.aq.cd x} `DivAmt))];
 divdata:aq__t3;
 .aq.initQueryState[];
 aq__t4:.aq.initTable[nosplit_avgpx;"nosplit_avgpx";1b];
 aq__t5:.aq.initTable[divdata;"divdata";1b];
 aq__t6:.aq.joinUsing[.aq.ej;aq__t4;aq__t5;({x^.aq.cd x} `Id;{x^.aq.cd x} `year)];
 aq__t6:?[aq__t6;();0b;((`Id);(`year);(`avg_px);(`total_divs);(`yield))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;(float;{x^.aq.cd x} `avg_px);(float;{x^.aq.cd x} `total_divs);(float;(%; {x^.aq.cd x} `total_divs; {x^.aq.cd x} `avg_px)))];
 aq__t6
 };
.aq.q9[]
