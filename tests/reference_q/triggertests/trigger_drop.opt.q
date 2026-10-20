// Translation begins here
.aq.show `table1 set ([]id:"j"$();qty:"j"$());

.trg.gen_trg_drop_me_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_drop_me];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`update];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;()];
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table1;"table1";0b];
 
 .aq.update[`table1;aq__t0;enlist ((=; {x^.aq.cd x} `id; 1));0b;(enlist[{x^.aq.cd x} `qty]!enlist (+; {x^.aq.cd x} `qty; 1))]
 ctx
 };
 .trg.register[`table1;`update;`after;`trg_drop_me;100;`.trg.gen_trg_drop_me_0];

.trg.drop[`trg_drop_me];
