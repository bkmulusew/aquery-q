// Translation begins here
// verbatim code

emp_hash_ssnum:update ssnum:`u#ssnum from employees;


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[emp_hash_ssnum;"emp_hash_ssnum";0b];
 aq__t0:?[aq__t0;enlist ((=; {x^.aq.cd x} `ssnum; 150));0b;()];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q0[]
