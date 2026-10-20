// Translation begins here
.aq.q0:{
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
.aq.q0[]
