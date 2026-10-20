// Translation begins here
// verbatim code

q9StartYear:{getYear maxTradeDateMinus3Years};
q9SplitIds:{exec distinct Id from split where Id in Russell2000, getYear[SplitDate] >= getYear maxTradeDateMinus3Years};


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[dividend;"dividend";0b];
 aq__t0:?[aq__t0;((.aq.in;{x^.aq.cd x} `Id;{x^.aq.cd x} `Russell2000);(>=; (getYear;{x^.aq.cd x} `AnnounceDate); (q9StartYear;));(.aq.not;(.aq.in;{x^.aq.cd x} `Id;(q9SplitIds;))));0b;()];
 aq__t0:?[aq__t0;();(({x^.aq.cd x} `Id);({x^.aq.cd x} `c__0))!({x^.aq.cd x} `Id;(getYear;{x^.aq.cd x} `AnnounceDate));({x^.aq.cd x} `Id;{x^.aq.cd x} `c__0) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`Id);(`c__0);(`c__1))!({x^.aq.cd x} `Id;(getYear';{x^.aq.cd x} `AnnounceDate);(.aq.sum';{x^.aq.cd x} `DivAmt))];
 divdata:`Id`year`total_divs xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[divdata;"divdata";0b];
 aq__t1:.aq.sort[aq__t1;((iasc;{x^.aq.cd x} `Id);(iasc;{x^.aq.cd x} `year));((.aq.wildCard aq__t1))];
 aq__t1:?[aq__t1;();0b;((`Id);(`year);(`total_divs))!({x^.aq.cd x} `Id;{x^.aq.cd x} `year;{x^.aq.cd x} `total_divs)];
 aq__t1
 };
.aq.q0[]
