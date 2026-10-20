// Translation begins here
// verbatim code

emp_sorted_ssnum:`ssnum xasc employees;
emp_sorted_ssnum:update ssnum:`s#ssnum from emp_sorted_ssnum;


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[emp_sorted_ssnum;"emp_sorted_ssnum";0b];
 aq__t0:?[aq__t0;enlist ((=; {x^.aq.cd x} `ssnum; 150));0b;()];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q0[]
