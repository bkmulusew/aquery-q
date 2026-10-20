// Translation begins here
.aq.show `t set ([]c1:"j"$();c2:"j"$();c3:"s"$());

.aq.insert[`t;t;();eval (enlist;1;2;`$"c")]

.aq.insert[`t;t;();eval (enlist;10;20;`$"C")]

.aq.show .aq.save[hsym `$"my_test_file.csv";","; ] {
  .aq.initQueryState[];
 aq__t0:.aq.initTable[t;"t";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 }[];

.aq.show `t2 set ([]c1:"j"$();c2:"j"$();c3:"s"$());

.aq.show .aq.load[hsym `$"my_test_file.csv";",";`t2];

// verbatim code
 .aq.q0:{t2}; system "rm -f my_test_file.csv" 
