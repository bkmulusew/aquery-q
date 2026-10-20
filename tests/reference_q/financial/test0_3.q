// Translation begins here
// verbatim code

constMonthly:{(count x)#`monthly};


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startYear10);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `startYear10; (*; 365; 10))));0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 Target:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[Target;"Target";0b];
 aq__t1:?[aq__t1;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getMonth;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(constMonthly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 monthly:`Id`bucket`name`low`high`mean xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[monthly;"monthly";0b];
 aq__t2:.aq.sort[aq__t2;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `bucket));((.aq.wildCard aq__t2))];
 aq__t2:?[aq__t2;();0b;((`Id);(`bucket);(`name);(`low);(`high);(`mean))!({x^.aq.cd x} `Id;{x^.aq.cd x} `bucket;{x^.aq.cd x} `name;{x^.aq.cd x} `low;{x^.aq.cd x} `high;{x^.aq.cd x} `mean)];
 aq__t2
 };
.aq.q0[]
