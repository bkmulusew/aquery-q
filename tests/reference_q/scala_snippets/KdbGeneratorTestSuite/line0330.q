// Translation begins here
.trg.gen_trg_sync_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`update];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"OLD TABLE AS deleted"];
  .aq.initQueryState[];
 deleted:.aq.initTable[.trg.oldRows ctx;"deleted";0b];
  aq__t0:.aq.initTable[table2;"table2";1b];
 aq__t1:.aq.initTable[deleted;"deleted";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;enlist ((=; {x^.aq.cd x} `table2.id; {x^.aq.cd x} `deleted.id));0b;()];
 aq__t2:?[aq__t2;();0b;((`id);(`qty);(`note))!({x^.aq.cd x} `table2.id;{x^.aq.cd x} `deleted.qty;{x^.aq.cd x} `deleted.note)];
 .trg.syncMappedUpdateRowsTo[aq__t2;`table2;enlist `id;enlist `id;`qty`note!`qty`note];
 ctx
 };
 .trg.register[`table1;`update;`after;`trg_sync;100;`.trg.gen_trg_sync_0];
