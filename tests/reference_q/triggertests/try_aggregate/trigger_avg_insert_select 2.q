// Translation begins here
.aq.show `orders set ([]id:"j"$();qty:"j"$());

.aq.show `avg_log set ([]avg_qty:"f"$());

.trg.gen_trg_avg_after_insert_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_avg_after_insert];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`insert];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.rows ctx;"inserted";0b];
 aq__t0:.aq.initTable[inserted;"inserted";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`avg_qty]!enlist (.aq.avg;{x^.aq.cd x} `qty))];
 aq__insert_src:aq__t0;
 .aq.insert[`avg_log;avg_log;();aq__insert_src]
 ctx
 };
 .trg.register[`orders;`insert;`after;`trg_avg_after_insert;100;`.trg.gen_trg_avg_after_insert_0];

.aq.insert[`orders;orders;();eval (enlist;1;10)]

.aq.insert[`orders;orders;();eval (enlist;2;20)]

// verbatim code

show orders;
show avg_log;

