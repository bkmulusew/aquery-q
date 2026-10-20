// Translation begins here
// verbatim code

nr:10000;
nc:10;
randf:{x?1000.0};
df_frame:flip (`$"c",/:string til nc)!flip (nr;nc)#randf nr * nc;
bool_arr:nr?01b;
df_groupby:([]key1:nr?`A`B`C; key2:nr?`one`two; value1:randf nr; value2:randf nr; value3:randf nr);
s_value_counts:([] val:`int$randf nr);
df_groupby_multi_python:([] key1:nr?10; key2:nr?10; data1:randf nr; data2:randf nr);
mdf1:df_frame;
mdf2:df_frame;
df_multi_join:update A:randf nr, B:randf nr, C:randf nr, D:randf nr from delete data1, data2 from df_groupby_multi_python;
df_join:df_groupby_multi_python;
s_std:([]val:randf nr);


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[df_frame;"df_frame";0b];
 aq__t0:?[aq__t0;enlist ({x^.aq.cd x} `bool_arr);0b;()];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q0[]

.aq.q1:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[df_groupby;"df_groupby";0b];
 aq__t0:?[aq__t0;();(({x^.aq.cd x} `key1);({x^.aq.cd x} `key2))!({x^.aq.cd x} `key1;{x^.aq.cd x} `key2);({x^.aq.cd x} `key1;{x^.aq.cd x} `key2) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`key1);(`key2);(`value1);(`value2);(`value3))!({x^.aq.cd x} `key1;{x^.aq.cd x} `key2;(.aq.avg';{x^.aq.cd x} `value1);(var';{x^.aq.cd x} `value1);(.aq.sum';{x^.aq.cd x} `value3))];
 aq__t0
 };
.aq.q1[]

.aq.q2:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[s_value_counts;"s_value_counts";0b];
 aq__t0:?[aq__t0;();(enlist[{x^.aq.cd x} `kval]!enlist {x^.aq.cd x} `val);({x^.aq.cd x} `kval) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`val);(`ct))!({x^.aq.cd x} `kval;(.aq.count';{x^.aq.cd x} `val))];
 aq__t0
 };
.aq.q2[]

.aq.q3:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[df_groupby_multi_python;"df_groupby_multi_python";0b];
 aq__t0:?[aq__t0;();(({x^.aq.cd x} `key1);({x^.aq.cd x} `key2))!({x^.aq.cd x} `key1;{x^.aq.cd x} `key2);({x^.aq.cd x} `key1;{x^.aq.cd x} `key2) _ (.aq.wildCard aq__t0)];
 aq__t0:?[aq__t0;();0b;((`key1);(`key2);(`val))!({x^.aq.cd x} `key1;{x^.aq.cd x} `key2;(.aq.sum';{x^.aq.cd x} `data1))];
 aq__t0
 };
.aq.q3[]

.aq.q4:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[eval (.aq.concatenate;(enlist;mdf1;mdf2));"";0b];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q4[]

.aq.q5:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[df_join;"df_join";1b];
 aq__t1:.aq.initTable[df_multi_join;"df_multi_join";1b];
 aq__t2:.aq.joinUsing[.aq.ej;aq__t0;aq__t1;({x^.aq.cd x} `key1;{x^.aq.cd x} `key2)];
 aq__t2:?[aq__t2;();0b;((`key1);(`key2);(`A);(`B);(`C);(`D);(`data1);(`data2))!({x^.aq.cd x} `key1;{x^.aq.cd x} `key2;{x^.aq.cd x} `A;{x^.aq.cd x} `B;{x^.aq.cd x} `C;{x^.aq.cd x} `D;{x^.aq.cd x} `data1;{x^.aq.cd x} `data2)];
 aq__t2
 };
.aq.q5[]

.aq.q6:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[s_std;"s_std";0b];
 aq__t0:?[aq__t0;();0b;(enlist[`std_dev]!enlist (dev;{x^.aq.cd x} `val))];
 aq__t0
 };
.aq.q6[]
