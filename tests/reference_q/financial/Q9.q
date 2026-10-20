// Translation begins here
// verbatim code

q9StartDate:{maxTradeDateMinus3Years};
q9StartYear:{getYear maxTradeDateMinus3Years};
q9SplitIds:{exec distinct Id from split where Id in Russell2000, getYear[SplitDate] >= getYear maxTradeDateMinus3Years};


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[price;"price";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(>=; {x^.aq.cd x} `TradeDate; (q9StartDate;));(.aq.not;(.aq.in;{x^.aq.cd x} `Id;(q9SplitIds;))));0b;()];
 aq__t0:?[aq__t0;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `year))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `TradeDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `year) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`Id);(`year);(`c__0))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;(.aq.avg';{x^.aq.cd x} `ClosePrice))];
 nosplit_avgpx:`Id`year`avg_px xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[dividend;"dividend";0b];
 aq__t1:?[aq__t1;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(>=; (getYear;{x^.aq.cd x} `AnnounceDate); (q9StartYear;));(.aq.not;(.aq.in;{x^.aq.cd x} `Id;(q9SplitIds;))));0b;()];
 aq__t1:?[aq__t1;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `year))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `AnnounceDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `year) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;();0b;((`Id);(`year);(`c__0))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;(.aq.sum';{x^.aq.cd x} `DivAmt))];
 divdata:`Id`year`total_divs xcol aq__t1;
 .aq.initQueryState[];
 aq__t2:.aq.initTable[nosplit_avgpx;"nosplit_avgpx";1b];
 aq__t3:.aq.initTable[divdata;"divdata";1b];
 aq__t4:.aq.joinUsing[.aq.ej;aq__t2;aq__t3;({x^.aq.cd x} `Id;{x^.aq.cd x} `year)];
 aq__t4:?[aq__t4;();0b;((`Id);(`year);(`avg_px);(`total_divs);(`yield))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;(float;{x^.aq.cd x} `avg_px);(float;{x^.aq.cd x} `total_divs);(float;(%; {x^.aq.cd x} `total_divs; {x^.aq.cd x} `avg_px)))];
 aq__t4
 };
.aq.q0[]
