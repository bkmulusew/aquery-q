// Translation begins here
.aq.show `table1 set ([]id:"j"$();subid:"j"$();qty:"j"$();note:"s"$());

.aq.show `table2 set ([]id:"j"$();subid:"j"$();qty:"j"$();note:"s"$());

.aq.insert[`table1;table1;();eval (enlist;1;10;100;`$"src_a")]

.aq.insert[`table1;table1;();eval (enlist;1;20;200;`$"src_b")]

.aq.insert[`table1;table1;();eval (enlist;2;10;300;`$"src_c")]

.aq.insert[`table2;table2;();eval (enlist;1;10;0;`$"dest_a")]

.aq.insert[`table2;table2;();eval (enlist;1;20;0;`$"dest_b")]

.aq.insert[`table2;table2;();eval (enlist;2;10;0;`$"dest_c")]

.trg.gen_trg_sync_table2_multikey_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_sync_table2_multikey];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`update];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.affectedResultRows ctx;"inserted";0b];
  aq__t0:.aq.initTable[table2;"table2";1b];
 aq__t1:.aq.initTable[inserted;"inserted";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;((=; {x^.aq.cd x} `table2.id; {x^.aq.cd x} `inserted.id);(=; {x^.aq.cd x} `table2.subid; {x^.aq.cd x} `inserted.subid));0b;()];
 aq__t2:?[aq__t2;();0b;((`id);(`subid);(`qty);(`note))!({x^.aq.cd x} `table2.id;{x^.aq.cd x} `table2.subid;{x^.aq.cd x} `inserted.qty;{x^.aq.cd x} `inserted.note)];
 .trg.syncMappedUpdateRowsTo[aq__t2;`table2;`id`subid;`id`subid;`qty`note!`qty`note];
 ctx
 };
 .trg.register[`table1;`update;`after;`trg_sync_table2_multikey;100;`.trg.gen_trg_sync_table2_multikey_0];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table1;"table1";0b];
 
 .aq.update[`table1;aq__t0;((=; {x^.aq.cd x} `id; 1);(=; {x^.aq.cd x} `subid; 10));0b;(({x^.aq.cd x} `qty);({x^.aq.cd x} `note))!(111;`$"src_a_updated")]
 }[];

// verbatim code

show table1;
show table2;

