// Translation begins here
// verbatim code

n:`int$1e6;
Ticks:([]ID:n?`S`ACME`OTHER`CORP; date:n?.z.D; timestamp:n?.z.P; price:n?100.0);
pointDate:first 1?Ticks`date;
Ticks:`date`ID xasc Ticks;
TicksWithAttr:update ID:`g#asc ID from Ticks;
Portfolio:([]ID:`S`ACME`OTHER`CORP; position:1e4+4?1e6);
Packets:select from ([]src:n?100; dest:n?100; length:n?256; timestamp:.z.P+10*n?`int$1e9) where src<>dest;
Sales:update sales:count[i]?1e6 from ([]month:`month${neg[x]?x}1+`long$`month$.z.D);
TradedStocks:([]ID:n?`S`ACME`OTHER`CORP; date:n?.z.D);
HistoricQuotes:update ClosePrice:count[i]?100. from `ID`date xcol distinct TradedStocks;
base:([] ID:(count .Q.a)?`S`ACME`OTHER`CORP; name:`$'.Q.a)


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Ticks;"Ticks";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;enlist ((=; {x^.aq.cd x} `ID; `$"ACME"));0b;()];
 aq__t0:?[aq__t0;();0b;(enlist[`price]!enlist {x^.aq.cd x} `price)];
 aq__t0
 };
.aq.q0[]

.aq.q1:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Ticks;"Ticks";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;((=; {x^.aq.cd x} `ID; `$"ACME");(=; {x^.aq.cd x} `date; {x^.aq.cd x} `pointDate));0b;()];
 aq__t0:?[aq__t0;();0b;(enlist[`max_profit]!enlist (.aq.max;(-; {x^.aq.cd x} `price; (.aq.mins1;{x^.aq.cd x} `price))))];
 aq__t0
 };
.aq.q1[]

.aq.q2:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Packets;"Packets";0b];
 aq__t0:.aq.sort[aq__t0;((iasc;{x^.aq.cd x} `src);(idesc;{x^.aq.cd x} `dest);(iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;();(({x^.aq.cd x} `src);({x^.aq.cd x} `dest);({x^.aq.cd x} `c__0))!({x^.aq.cd x} `src;{x^.aq.cd x} `dest;(.aq.sums1;(>; (.aq.deltas;{x^.aq.cd x} `timestamp); (*; 120; 1000000000))));({x^.aq.cd x} `src;{x^.aq.cd x} `dest;{x^.aq.cd x} `c__0) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`src);(`dest);(`len);(`ct))!({x^.aq.cd x} `src;{x^.aq.cd x} `dest;(.aq.avg';{x^.aq.cd x} `length);(.aq.count';{x^.aq.cd x} `timestamp))];
 aq__t0
 };
.aq.q2[]

.aq.q3:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Ticks;"Ticks";0b];
 aq__t0:.aq.sort[aq__t0;((iasc;{x^.aq.cd x} `ID);(iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;();(enlist[{x^.aq.cd x} `ID]!enlist {x^.aq.cd x} `ID);({x^.aq.cd x} `ID) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`ID);(`date);(`timestamp);(`c__0);(`c__1))!({x^.aq.cd x} `ID;{x^.aq.cd x} `date;{x^.aq.cd x} `timestamp;(.aq.avgs2';21;{x^.aq.cd x} `price);(.aq.avgs2';5;{x^.aq.cd x} `price))];
 averages:`ID`date`timestamp`a21`a5 xcol aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[eval (.aq.flatten;averages);"";0b];
 aq__t1:.aq.sort[aq__t1;((iasc;{x^.aq.cd x} `ID);(iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t1))];
 aq__t1:?[aq__t1;enlist ((&; (&; (>; {x^.aq.cd x} `a21; {x^.aq.cd x} `a5); (<=; (.aq.prev1;{x^.aq.cd x} `a21); (.aq.prev1;{x^.aq.cd x} `a5))); (=; (.aq.prev1;{x^.aq.cd x} `ID); {x^.aq.cd x} `ID)));0b;()];
 aq__t1:?[aq__t1;();0b;((`ID);(`date))!({x^.aq.cd x} `ID;{x^.aq.cd x} `date)];
 aq__t1
 };
.aq.q3[]

.aq.q4:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Ticks;"t";1b];
 aq__t1:.aq.initTable[Portfolio;"p";1b];
 aq__t2:.aq.joinUsing[.aq.ej;aq__t0;aq__t1;enlist ({x^.aq.cd x} `ID)];
 aq__t2:.aq.sort[aq__t2;enlist ((iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t2))];
 aq__t2:?[aq__t2;();(enlist[{x^.aq.cd x} `t.ID]!enlist {x^.aq.cd x} `t.ID);({x^.aq.cd x} `t.ID) _ (.aq.wildCard aq__t2)];
 aq__t2:?[aq__t2;();0b;((`ID);(`last_price))!({x^.aq.cd x} `t.ID;(.aq.last2';10;{x^.aq.cd x} `price))];
 aq__t2
 };
.aq.q4[]

.aq.q5:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Ticks;"Ticks";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;enlist ((=; {x^.aq.cd x} `date; {x^.aq.cd x} `pointDate));0b;()];
 aq__t0:?[aq__t0;();0b;((`ID);(`price);(`timestamp))!({x^.aq.cd x} `ID;{x^.aq.cd x} `price;{x^.aq.cd x} `timestamp)];
 OneDay:aq__t0;
 .aq.initQueryState[];
 aq__t1:.aq.initTable[OneDay;"OneDay";0b];
 aq__t1:.aq.sort[aq__t1;enlist ((iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t1))];
 aq__t1:?[aq__t1;enlist ((<; `i; 1000));0b;()];
 aq__t1:?[aq__t1;();(enlist[{x^.aq.cd x} `ID]!enlist {x^.aq.cd x} `ID);({x^.aq.cd x} `ID) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;();0b;((`ID);(`ct))!({x^.aq.cd x} `ID;(.aq.count';{x^.aq.cd x} `timestamp))];
 aq__t1
 };
.aq.q5[]

.aq.q6:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Sales;"Sales";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `month));((.aq.wildCard aq__t0))];
 aq__t0:?[aq__t0;();0b;((`month);(`moving_sales))!({x^.aq.cd x} `month;(.aq.avgs2;3;{x^.aq.cd x} `sales))];
 aq__t0
 };
.aq.q6[]

.aq.q7:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[TradedStocks;"ts";1b];
 aq__t1:.aq.initTable[HistoricQuotes;"hq";1b];
 aq__t2:.aq.joinUsing[.aq.ej;aq__t0;aq__t1;({x^.aq.cd x} `ID;{x^.aq.cd x} `date)];
 aq__t2:.aq.sort[aq__t2;enlist ((iasc;{x^.aq.cd x} `date));((.aq.wildCard aq__t2))];
 aq__t2:?[aq__t2;();(enlist[{x^.aq.cd x} `ID]!enlist {x^.aq.cd x} `ID);({x^.aq.cd x} `ID) _ (.aq.wildCard aq__t2)];
 aq__t2:?[aq__t2;();0b;((`ID);(`avg_price))!({x^.aq.cd x} `ID;(.aq.avgs2';10;{x^.aq.cd x} `hq.ClosePrice))];
 aq__t2
 };
.aq.q7[]

.aq.q8:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[Ticks;"t";1b];
 aq__t1:.aq.initTable[base;"b";1b];
 aq__t2:.aq.joinUsing[.aq.ej;aq__t0;aq__t1;enlist ({x^.aq.cd x} `ID)];
 aq__t2:.aq.sort[aq__t2;((iasc;{x^.aq.cd x} `name);(iasc;{x^.aq.cd x} `timestamp));((.aq.wildCard aq__t2))];
 aq__t2:?[aq__t2;enlist ((=; {x^.aq.cd x} `name; `$"x"));0b;()];
 aq__t2:?[aq__t2;();0b;(enlist[`last_price]!enlist (.aq.last1;{x^.aq.cd x} `price))];
 aq__t2
 };
.aq.q8[]

.aq.q9:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[TicksWithAttr;"t";1b];
 aq__t1:.aq.initTable[Portfolio;"p";1b];
 aq__t2:.aq.joinUsing[.aq.ej;aq__t0;aq__t1;enlist ({x^.aq.cd x} `ID)];
 aq__t2:?[aq__t2;enlist ((<; `i; 1000));0b;()];
 aq__t2:?[aq__t2;();0b;((`ID);(`date);(`timestamp);(`price))!({x^.aq.cd x} `ID;{x^.aq.cd x} `date;{x^.aq.cd x} `timestamp;{x^.aq.cd x} `price)];
 aq__t2
 };
.aq.q9[]

pythag:{[x;y]
  sqr_x:eval (*; .aq.funEnlist x; .aq.funEnlist x);
  sqr_y:eval (*; .aq.funEnlist y; .aq.funEnlist y);
 eval (.aq.sqrt;(+; .aq.funEnlist sqr_x; .aq.funEnlist sqr_y))
 };

// verbatim code
.aq.q10:{pythag(3,4)}

// verbatim code

t1:([]c1:1 2 3; c2:10 20 30);
t2:([]c1:100 200 300; c2:1000 2000 3000);
tu1:([]c1:1 1 1 2 2 3 4 4; c2:10 10 20 30 30 60 70 80);
tu2:([]c1:100 -100 200 300; c2:20 30 10 40);


.aq.show `aq_t1 set ([]c1:"j"$();c2:"j"$());

.aq.insert[`aq_t1;
 {
  .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_t1;"aq_t1";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `c1));((.aq.wildCard aq__t0))];
 aq__t0 
 }[];();
 {
  .aq.initQueryState[];
 aq__t1:.aq.initTable[t2;"t2";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1)];
 aq__t1
 }[]]

.aq.insert[`aq_t1;aq_t1;`c2`c1;eval (enlist;-1;-2)]

.aq.q10:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_t1;"aq_t1";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q10[]

.aq.show `aq_tu1 set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[tu1;"tu1";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_tu1;"aq_tu1";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `c2));((.aq.wildCard aq__t0))];
 
 .aq.initQueryState[];
 aq__t1:.aq.initTable[aq__t0;"aq__t0";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1),(enlist[`aq__ix]!enlist `i)];
 aq__t1:?[aq__t1;enlist ((<; {x^.aq.cd x} `c1; 3));0b;()];
 aq__t1:?[aq__t1;();(({x^.aq.cd x} `c1);({x^.aq.cd x} `c2))!({x^.aq.cd x} `c1;{x^.aq.cd x} `c2);({x^.aq.cd x} `c1;{x^.aq.cd x} `c2) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;enlist ((>=; (.aq.count';{x^.aq.cd x} `c2); 2));0b;()];
  aq__ix:@[(count aq__t0)#0b;(ungroup 0!aq__t1)`aq__ix;:;1b];

 .aq.update[`aq_tu1;aq__t0;enlist aq__ix;(({x^.aq.cd x} `c1);({x^.aq.cd x} `c2))!({x^.aq.cd x} `c1;{x^.aq.cd x} `c2);(enlist[{x^.aq.cd x} `c3]!enlist (.aq.last1;(.aq.sums1;{x^.aq.cd x} `c2)))]
 }[];

.aq.q11:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_tu1;"aq_tu1";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q11[]

.aq.show `aq_tu2 set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[tu2;"tu2";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_tu2;"aq_tu2";0b];
 
 .aq.update[`aq_tu2;aq__t0;enlist ((>; {x^.aq.cd x} `c1; 0));0b;(enlist[{x^.aq.cd x} `c3]!enlist (.aq.max;{x^.aq.cd x} `c2))]
 }[];

.aq.q12:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_tu2;"aq_tu2";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q12[]

.aq.show `aq_td1 set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[tu1;"tu1";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_td1;"aq_td1";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `c2));((.aq.wildCard aq__t0))];
 
 .aq.initQueryState[];
 aq__t1:.aq.initTable[aq__t0;"aq__t0";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1),(enlist[`aq__ix]!enlist `i)];
 aq__t1:?[aq__t1;enlist ((<; {x^.aq.cd x} `c1; 3));0b;()];
 aq__t1:?[aq__t1;();(enlist[{x^.aq.cd x} `c1]!enlist {x^.aq.cd x} `c1);({x^.aq.cd x} `c1) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;enlist ((>; (.aq.count';{x^.aq.cd x} `c2); 1));0b;()];
  aq__ix:@[(count aq__t0)#0b;(ungroup 0!aq__t1)`aq__ix;:;1b];

 .aq.deleteRows[`aq_td1;aq__t0;enlist aq__ix]
 }[];

.aq.q13:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_td1;"aq_td1";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q13[]

.aq.show `aq_td2 set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[tu2;"tu2";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

.aq.show `aq_td2 set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_td2;"aq_td2";0b];
 
 ![aq_td2;();0b;enlist ({x^.aq.cd x} `c2)]
 }[];

.aq.q14:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[aq_td2;"aq_td2";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q14[]
