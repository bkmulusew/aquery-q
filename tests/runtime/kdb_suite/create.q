.kdb.c1:{([]c1:`long$();c2:`$();c3:`boolean$())};
.kdb.c2:{
  select c1:c1 * 2, c2, max_c3:c3 from select sums c2, max c3 by c1 from `c3 xasc base where c1 > 10
  }
