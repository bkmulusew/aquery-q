// Translation begins here
.trg.gen_trg_sync_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync];
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
 .trg.register[`table1;`update;`after;`trg_sync;100;`.trg.gen_trg_sync_0];
