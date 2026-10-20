// Translation begins here
.aq.show `table1 set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.show `table2 set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.insert[`table1;table1;();eval (enlist;1;10;`$"src_old")]

.aq.insert[`table1;table1;();eval (enlist;2;20;`$"src2")]

.aq.insert[`table2;table2;();eval (enlist;1;0;`$"dest")]

.aq.insert[`table2;table2;();eval (enlist;2;0;`$"dest2")]

.trg.gen_trg_sync_table2_old_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync_table2_old];
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
 .trg.register[`table1;`update;`after;`trg_sync_table2_old;100;`.trg.gen_trg_sync_table2_old_0];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table1;"table1";0b];
 
 .aq.update[`table1;aq__t0;enlist ((=; {x^.aq.cd x} `id; 1));0b;(({x^.aq.cd x} `qty);({x^.aq.cd x} `note))!(42;`$"src_new")]
 }[];

// verbatim code

show table1;
show table2;

