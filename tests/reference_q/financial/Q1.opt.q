// Translation begins here
.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;.aq.reorderFilter[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `start300Days);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `start300Days; 300)))];0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`HighPrice);(`LowPrice);(`ClosePrice);(`OpenPrice);(`Volume))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `HighPrice;{x^.aq.cd x} `LowPrice;{x^.aq.cd x} `ClosePrice;{x^.aq.cd x} `OpenPrice;{x^.aq.cd x} `Volume)];
 pxdata:`Id`TradeDate`HighPrice`LowPrice`ClosePrice`OpenPrice`Volume xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[split;"split";0b];
 aq__t1:?[aq__t1;.aq.reorderFilter[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock1000);(>=; {x^.aq.cd x} `SplitDate; {x^.aq.cd x} `start300Days))];0b;()];
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
 aq__t7:.aq.sort[aq__t7;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `ClosePrice;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `AdjFactor;{x^.aq.cd x} `HighPrice;{x^.aq.cd x} `LowPrice;{x^.aq.cd x} `OpenPrice;{x^.aq.cd x} `Volume;{x^.aq.cd x} `Id)];
 aq__t7:?[aq__t7;();0b;((`Id);(`TradeDate);(`c__0);(`c__1);(`c__2);(`c__3);(`c__4))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;(*; {x^.aq.cd x} `HighPrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(*; {x^.aq.cd x} `LowPrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(*; {x^.aq.cd x} `ClosePrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(*; {x^.aq.cd x} `OpenPrice; (.aq.fill;1;{x^.aq.cd x} `AdjFactor));(%; {x^.aq.cd x} `Volume; (.aq.fill;1;{x^.aq.cd x} `AdjFactor)))];
 aq__t7
 };
.aq.q0[]
