// Translation begins here
// verbatim code

constWeekly:{(count x)#`weekly};
constMonthly:{(count x)#`monthly};
constYearly:{(count x)#`yearly};


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;.aq.reorderFilter[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `stock10);(>=; {x^.aq.cd x} `TradeDate; {x^.aq.cd x} `startYear10);(<=; {x^.aq.cd x} `TradeDate; (+; {x^.aq.cd x} `startYear10; (*; 365; 10))))];0b;()];
 aq__t0:?[aq__t0;();0b;((`Id);(`TradeDate);(`ClosePrice))!({x^.aq.cd x} `Id;{x^.aq.cd x} `TradeDate;{x^.aq.cd x} `ClosePrice)];
 Target:`Id`TradeDate`ClosePrice xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[Target;"Target";0b];
 aq__t1:?[aq__t1;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getWeek;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(constWeekly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 weekly:`Id`bucket`name`low`high`mean xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[Target;"Target";0b];
 aq__t2:?[aq__t2;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getMonth;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t2)];
 aq__t2:?[aq__t2;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(constMonthly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 monthly:`Id`bucket`name`low`high`mean xcol aq__t2;
 .aq.initQueryState[];
 aq__t3:.aq.initTable[Target;"Target";0b];
 aq__t3:?[aq__t3;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `timeBucket))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket) _ (.aq.wildCard aq__t3)];
 aq__t3:?[aq__t3;();0b;((`Id);(`timeBucket);(`c__0);(`c__1);(`c__2);(`c__3))!({x^.aq.cd x} `Id;{x^.aq.cd x} `timeBucket;(constYearly';{x^.aq.cd x} `Id);(.aq.min';{x^.aq.cd x} `ClosePrice);(.aq.max';{x^.aq.cd x} `ClosePrice);(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 yearly:`Id`bucket`name`low`high`mean xcol aq__t3;
 .aq.initQueryState[];
 aq__t4:.aq.initTable[eval (.aq.concatenate;(enlist;weekly;monthly;yearly));"";0b];
 aq__t4:.aq.sort[aq__t4;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `name);(iasc;{x^.aq.cd x} `bucket));({x^.aq.cd x} `mean;{x^.aq.cd x} `bucket;{x^.aq.cd x} `name;{x^.aq.cd x} `low;{x^.aq.cd x} `high;{x^.aq.cd x} `Id)];
 aq__t4:?[aq__t4;();0b;((`Id);(`bucket);(`name);(`low);(`high);(`mean))!({x^.aq.cd x} `Id;{x^.aq.cd x} `bucket;{x^.aq.cd x} `name;{x^.aq.cd x} `low;{x^.aq.cd x} `high;{x^.aq.cd x} `mean)];
 aq__t4
 };
.aq.q0[]
