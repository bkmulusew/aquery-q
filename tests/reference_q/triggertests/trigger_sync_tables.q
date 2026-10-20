// Translation begins here
.aq.show `table1 set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.show `table2 set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.insert[`table1;table1;();eval (enlist;1;10;`$"src")]

.aq.insert[`table1;table1;();eval (enlist;2;20;`$"src2")]

.aq.insert[`table2;table2;();eval (enlist;1;0;`$"dest")]

.aq.insert[`table2;table2;();eval (enlist;2;0;`$"dest2")]

.trg.gen_trg_sync_table2_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync_table2];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`update];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;()];
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table2;"table2";0b];
 
 .aq.update[`table2;aq__t0;enlist ((=; {x^.aq.cd x} `id; 1));0b;(({x^.aq.cd x} `qty);({x^.aq.cd x} `note))!((+; {x^.aq.cd x} `qty; 100);`$"updated_by_trigger")]
 ctx
 };
 .trg.register[`table1;`update;`after;`trg_sync_table2;100;`.trg.gen_trg_sync_table2_0];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table1;"table1";0b];
 
 .aq.update[`table1;aq__t0;enlist ((=; {x^.aq.cd x} `id; 1));0b;(enlist[{x^.aq.cd x} `qty]!enlist 42)]
 }[];

// verbatim code

show table1;
show table2;

