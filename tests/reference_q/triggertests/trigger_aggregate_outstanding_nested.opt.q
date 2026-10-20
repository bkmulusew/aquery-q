// Translation begins here
.aq.show `orders set ([]ordernum:"j"$();itemnum:"j"$();quantity:"j"$();lineAmount:"j"$();storeid:"s"$();vendorid:"s"$());

.aq.show `item set ([]itemnum:"j"$();price:"j"$());

.aq.show `vendorOutstanding set ([]vendorid:"s"$();amount:"j"$());

.aq.show `storeOutstanding set ([]storeid:"s"$();amount:"j"$());

.aq.insert[`item;item;();eval (enlist;101;5)]

.aq.insert[`item;item;();eval (enlist;102;7)]

.aq.insert[`vendorOutstanding;vendorOutstanding;();eval (enlist;`$"V1";1000)]

.aq.insert[`vendorOutstanding;vendorOutstanding;();eval (enlist;`$"V2";2000)]

.aq.insert[`storeOutstanding;storeOutstanding;();eval (enlist;`$"S1";100)]

.aq.insert[`storeOutstanding;storeOutstanding;();eval (enlist;`$"S2";200)]

.trg.gen_updateVendorOutstanding_0:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`updateVendorOutstanding];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`insert];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.rows ctx;"inserted";0b];
  aq__t0:.aq.initTable[vendorOutstanding;"vendorOutstanding";1b];
 aq__t1:.aq.initTable[inserted;"inserted";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;enlist ((=; {x^.aq.cd x} `vendorOutstanding.vendorid; {x^.aq.cd x} `inserted.vendorid));0b;()];
 aq__t2:?[aq__t2;();0b;((`vendorid);(`amount))!({x^.aq.cd x} `vendorOutstanding.vendorid;(+; {x^.aq.cd x} `amount; {x^.aq.cd x} `inserted.lineAmount))];
 .trg.syncMappedUpdateRowsTo[aq__t2;`vendorOutstanding;enlist `vendorid;enlist `vendorid;(enlist `amount)!enlist `amount];
 ctx
 };
 .trg.register[`orders;`insert;`after;`updateVendorOutstanding;100;`.trg.gen_updateVendorOutstanding_0];

.trg.gen_updateStoreOutstanding_1:{[tbl;evt;ctx]
 ctx:.trg.ctxSet[ctx;`triggerName;`updateStoreOutstanding];
 ctx:.trg.ctxSet[ctx;`triggerTable;`orders];
 ctx:.trg.ctxSet[ctx;`triggerEvent;`insert];
 ctx:.trg.ctxSet[ctx;`triggerTiming;`after];
 ctx:.trg.ctxSet[ctx;`triggerRefs;"NEW TABLE AS inserted"];
  .aq.initQueryState[];
 inserted:.aq.initTable[.trg.rows ctx;"inserted";0b];
  aq__t0:.aq.initTable[storeOutstanding;"storeOutstanding";1b];
 aq__t1:.aq.initTable[inserted;"inserted";1b];
 aq__t2:aq__t0 cross aq__t1;
 aq__t2:?[aq__t2;enlist ((=; {x^.aq.cd x} `storeOutstanding.storeid; {x^.aq.cd x} `inserted.storeid));0b;()];
 aq__t2:?[aq__t2;();0b;((`storeid);(`amount))!({x^.aq.cd x} `storeOutstanding.storeid;(+; {x^.aq.cd x} `amount; {x^.aq.cd x} `inserted.lineAmount))];
 .trg.syncMappedUpdateRowsTo[aq__t2;`storeOutstanding;enlist `storeid;enlist `storeid;(enlist `amount)!enlist `amount];
 ctx
 };
 .trg.register[`orders;`insert;`after;`updateStoreOutstanding;100;`.trg.gen_updateStoreOutstanding_1];

.aq.insert[`orders;orders;();eval (enlist;1;101;3;15;`$"S1";`$"V1")]

.aq.insert[`orders;orders;();eval (enlist;2;102;2;14;`$"S2";`$"V2")]

// verbatim code

.aq.vendor_after:{vendorOutstanding};
.aq.store_after:{storeOutstanding};
show orders;
show vendorOutstanding;
show storeOutstanding;

