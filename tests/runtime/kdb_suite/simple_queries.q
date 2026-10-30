.kdb.c1:{update c1:c1 * 2, c3:?[c3 > 50;1;-1] from `c1 xasc base};
.kdb.c2:{delete from base where ({(any bi[`c3]>2)&4<count bi:base[x]};i) fby c1}
