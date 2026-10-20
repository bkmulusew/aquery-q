// Translation begins here
.trg.gen_trg_ins_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_ins];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`insert];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;()];
 .aq.initQueryState[];
 aq__t0:.aq.initTable[orders;"orders";0b];
 
 .aq.update[`orders;aq__t0;();0b;(enlist[{x^.aq.cd x} `qty]!enlist 0)]
 ctx
 };
 .trg.register[`orders;`insert;`after;`trg_ins;100;`.trg.gen_trg_ins_0];
