// Translation begins here
.trg.gen_trg_sync_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`delete];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`before];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"OLD TABLE AS deleted"];
  .aq.initQueryState[];
 deleted:.aq.initTable[.trg.oldRows ctx;"deleted";0b];
 aq__t0:.aq.initTable[deleted;"deleted";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__insert_src:aq__t0;
 .aq.insert[`audit;audit;();aq__insert_src]
 ctx
 };
 .trg.register[`table1;`delete;`before;`trg_sync;100;`.trg.gen_trg_sync_0];
