.aq.show `t set ([]a:"j"$();b:"f"$();c:"s"$();d:"d"$();e:"p"$();f:"b"$());

.aq.show `u set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];
 aq__t0
 }[];

.aq.insert[`t;t;();eval (enlist;1;2.0;`$"x")]

.aq.insert[`t;t;`a`b;eval (enlist;1;2.0)]

.aq.insert[`t;t;();eval (enlist;1)]

.aq.insert[`t;
 {
  .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `a));((.aq.wildCard aq__t0))];
 aq__t0 
 }[];();
 {
  .aq.initQueryState[];
 aq__t1:.aq.initTable[u;"u";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1)];
 aq__t1
 }[]]

.aq.insert[`t;t;enlist `a;
 {
  .aq.initQueryState[];
 aq__t0:.aq.initTable[u;"u";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];
 aq__t0
 }[]]

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 .aq.update[`t;aq__t0;enlist ((>; {x^.aq.cd x} `b; 1));0b;(enlist[{x^.aq.cd x} `a]!enlist (+; {x^.aq.cd x} `a; 1))]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `a));((.aq.wildCard aq__t0))];
 
 .aq.update[`t;aq__t0;enlist ((>; {x^.aq.cd x} `b; 1));(enlist[{x^.aq.cd x} `c]!enlist {x^.aq.cd x} `c);(({x^.aq.cd x} `a);({x^.aq.cd x} `b))!((.aq.sums1;{x^.aq.cd x} `b);2)]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 .aq.initQueryState[];
 aq__t1:.aq.initTable[aq__t0;"aq__t0";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1),(enlist[`aq__ix]!enlist `i)];
 aq__t1:?[aq__t1;();0b;()];
 aq__t1:?[aq__t1;();(enlist[{x^.aq.cd x} `c]!enlist {x^.aq.cd x} `c);({x^.aq.cd x} `c) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;enlist ((>; (.aq.count';{x^.aq.cd x} `a); 1));0b;()];
  aq__ix:@[(count aq__t0)#0b;(ungroup 0!aq__t1)`aq__ix;:;1b];

 .aq.update[`t;aq__t0;enlist aq__ix;(enlist[{x^.aq.cd x} `c]!enlist {x^.aq.cd x} `c);(enlist[{x^.aq.cd x} `a]!enlist 1)]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 .aq.update[`t;aq__t0;();0b;(enlist[{x^.aq.cd x} `a]!enlist 1)]
 }[];

.aq.show `t set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 ![t;();0b;({x^.aq.cd x} `a;{x^.aq.cd x} `b)]
 }[];

.aq.show `t set {
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 ![t;();0b;enlist ({x^.aq.cd x} `a)]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 .aq.deleteRows[`t;aq__t0;enlist ((>; {x^.aq.cd x} `a; 1))]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 
 .aq.deleteRows[`t;aq__t0;()]
 }[];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:.aq.sort[aq__t0;enlist ((iasc;{x^.aq.cd x} `b));((.aq.wildCard aq__t0))];
 
 .aq.initQueryState[];
 aq__t1:.aq.initTable[aq__t0;"aq__t0";0b];
 aq__t1:?[aq__t1;();0b;(.aq.wildCard aq__t1),(enlist[`aq__ix]!enlist `i)];
 aq__t1:?[aq__t1;enlist ((>; {x^.aq.cd x} `a; 1));0b;()];
 aq__t1:?[aq__t1;();(enlist[{x^.aq.cd x} `c]!enlist {x^.aq.cd x} `c);({x^.aq.cd x} `c) _ (.aq.wildCard aq__t1)];
 aq__t1:?[aq__t1;enlist ((>; (.aq.count';{x^.aq.cd x} `a); 1));0b;()];
  aq__ix:@[(count aq__t0)#0b;(ungroup 0!aq__t1)`aq__ix;:;1b];

 .aq.deleteRows[`t;aq__t0;enlist aq__ix]
 }[];

.aq.show .aq.load[hsym `$"f.csv";",";`t];

.aq.show .aq.save[hsym `$"g.csv";"|"; ] {
  .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`a]!enlist {x^.aq.cd x} `a)];
 aq__t0
 }[];

f:{[x;y]
  z:eval (+; .aq.funEnlist x; .aq.funEnlist y);
 eval (*; .aq.funEnlist z; 2)
 };

g:{[]
 eval 1
 };
