// Translation begins here
.aq.show `orders set ([]id:"j"$();qty:"j"$());

.aq.show `sum_log set ([]total:"j"$());

.trg.gen_trg_sum_after_insert_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sum_after_insert];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`insert];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.rows ctx;"inserted";0b];
 aq__t0:.aq.initTable[inserted;"inserted";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`total]!enlist (.aq.sum;{x^.aq.cd x} `qty))];
 aq__insert_src:aq__t0;
 .aq.insert[`sum_log;sum_log;();aq__insert_src]
 ctx
 };
 .trg.register[`orders;`insert;`after;`trg_sum_after_insert;100;`.trg.gen_trg_sum_after_insert_0];

.aq.insert[`orders;orders;();eval (enlist;1;10)]

.aq.insert[`orders;orders;();eval (enlist;2;20)]

// verbatim code

show orders;
show sum_log;

