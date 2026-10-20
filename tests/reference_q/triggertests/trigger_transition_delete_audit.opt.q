// Translation begins here
.aq.show `table1 set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.show `audit set ([]id:"j"$();qty:"j"$();note:"s"$());

.aq.insert[`table1;table1;();eval (enlist;1;10;`$"src_old")]

.aq.insert[`table1;table1;();eval (enlist;2;20;`$"src2")]

.trg.gen_trg_audit_deleted_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`trg_audit_deleted];
 ctx:.trg.ctxSet[ctx;`triggerTable;`table1];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`delete];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`before];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"OLD TABLE AS deleted"];
  .aq.initQueryState[];
 deleted:.aq.initTable[.trg.oldRows ctx;"deleted";0b];
 aq__t0:.aq.initTable[deleted;"deleted";0b];
 aq__t0:?[aq__t0;();0b;((`id);(`qty);(`note))!({x^.aq.cd x} `id;{x^.aq.cd x} `qty;{x^.aq.cd x} `note)];
 aq__insert_src:aq__t0;
 .aq.insert[`audit;audit;();aq__insert_src]
 ctx
 };
 .trg.register[`table1;`delete;`before;`trg_audit_deleted;100;`.trg.gen_trg_audit_deleted_0];

{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[table1;"table1";0b];
 
 .aq.deleteRows[`table1;aq__t0;enlist ((=; {x^.aq.cd x} `id; 1))]
 }[];

// verbatim code

show table1;
show audit;

