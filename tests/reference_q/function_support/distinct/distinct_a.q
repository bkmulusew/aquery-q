// Translation begins here
// verbatim code

employee


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[employee;"employee";1b];
 aq__t1:.aq.initTable[techdept;"techdept";1b];
 aq__t2:.aq.joinUsing[.aq.ej;aq__t0;aq__t1;enlist ({x^.aq.cd x} `dept)];
 aq__t2:?[aq__t2;();0b;(enlist[`ssnum]!enlist {x^.aq.cd x} `ssnum)];
 aq__t2
 };
.aq.q0[]
