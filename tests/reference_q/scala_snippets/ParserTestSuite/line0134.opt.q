// Translation begins here
.trg.gen_trg_upd_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_upd];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`update];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"OLD TABLE AS deleted, NEW TABLE AS inserted"];
 .aq.q1:{
 .aq.initQueryState[];
 deleted:.aq.initTable[.trg.oldRows ctx;"deleted";0b];
 inserted:.aq.initTable[.trg.affectedResultRows ctx;"inserted";0b];
 aq__t0:.aq.initTable[inserted;"inserted";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q1[]
 ctx
 };
 .trg.register[`orders;`update;`after;`trg_upd;100;`.trg.gen_trg_upd_0];
