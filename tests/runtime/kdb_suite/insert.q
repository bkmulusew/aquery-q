.kdb.q0:{
  t:([]c1:`long$(); c2:`long$(); c3:`$());
  t:t upsert (1;2;`c);
  t:t upsert (10;20;`C);
  t:t upsert select c1:c2, c2, c3:`$"this is a test" from base;
  t
  }
