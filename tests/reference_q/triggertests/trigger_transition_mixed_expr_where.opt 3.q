// Translation begins here
.aq.show `table1 set ([]id:"j"$();delta:"j"$();limit:"j"$());

.aq.show `table2 set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.insert[`table1;table1;();eval (enlist;1;5;20)]

.aq.insert[`table1;table1;();eval (enlist;2;7;50)]

.aq.insert[`table2;table2;();eval (enlist;1;10;`$"dest1")]

.aq.insert[`table2;table2;();eval (enlist;2;100;`$"dest2")]

.trg.gen_trg_sync_mixed_expr_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync_mixed_expr];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`update];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.affectedResultRows ctx;"inserted";0b];
  aq__t0:.aq.initTable[table2;"table2";1b];
 aq__t1:.aq.initTable[inserted;"inserted";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;((=; {x^.aq.cd x} `table2.id; {x^.aq.cd x} `inserted.id);(<; {x^.aq.cd x} `table2.qty; {x^.aq.cd x} `inserted.limit));0b;()];
 aq__t2:?[aq__t2;();0b;((`id);(`qty))!({x^.aq.cd x} `table2.id;(+; {x^.aq.cd x} `table2.qty; {x^.aq.cd x} `inserted.delta))];
 .trg.syncMappedUpdateRowsTo[aq__t2;`table2;enlist `id;enlist `id;(enlist `qty)!enlist `qty];
 ctx
 };
 .trg.register[`table1;`update;`after;`trg_sync_mixed_expr;100;`.trg.gen_trg_sync_mixed_expr_0];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table1;"table1";0b];
 
 .aq.update[`table1;aq__t0;enlist ((=; {x^.aq.cd x} `id; 1));0b;(({x^.aq.cd x} `delta);({x^.aq.cd x} `limit))!(9;25)]
 }[];

// verbatim code

show table1;
show table2;

