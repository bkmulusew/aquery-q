// Translation begins here
// verbatim code

trade:([] sym:`AAPL`MSFT; qty:2 3i; price:10 20f);


{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[trade;"trade";0b];
 
 .aq.update[`trade;aq__t0;enlist ((=; {x^.aq.cd x} `sym; `$"AAPL"));0b;(enlist[{x^.aq.cd x} `qty]!enlist 5)]
 }[];
