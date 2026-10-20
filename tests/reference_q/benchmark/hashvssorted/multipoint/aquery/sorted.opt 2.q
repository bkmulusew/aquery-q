// Translation begins here
// verbatim code

emp_sorted_hundreds1:`hundreds1 xasc employees;
emp_sorted_hundreds1:update hundreds1:`s#hundreds1 from emp_sorted_hundreds1;


.aq.q0:{
 .aq.initQueryState[];
 aq__t0:.aq.initTable[emp_sorted_hundreds1;"emp_sorted_hundreds1";0b];
 aq__t0:?[aq__t0;enlist ((=; {x^.aq.cd x} `hundreds1; 150));0b;()];
 aq__t0:?[aq__t0;();0b;(.aq.wildCard aq__t0)];
 aq__t0
 };
.aq.q0[]
