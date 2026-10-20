// Translation begins here
.aq.show `orders set ([]id:"j"$();qty:"j"$());

.aq.show `count_log set ([]cnt:"j"$());

.trg.gen_trg_count_after_insert_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_count_after_insert];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`insert];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.rows ctx;"inserted";0b];
 aq__t0:.aq.initTable[inserted;"inserted";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`cnt]!enlist (.aq.count;{x^.aq.cd x} `qty))];
 aq__insert_src:aq__t0;
 .aq.insert[`count_log;count_log;();aq__insert_src]
 ctx
 };
 .trg.register[`orders;`insert;`after;`trg_count_after_insert;100;`.trg.gen_trg_count_after_insert_0];

.aq.insert[`orders;orders;();eval (enlist;1;10)]

.aq.insert[`orders;orders;();eval (enlist;2;20)]

// verbatim code

show orders;
show count_log;

