// Translation begins here
f:{[]
  x:eval (-; (*; 100; 2); 3);
  y:eval (.aq.pow; .aq.funEnlist x; 3);
  l:eval (.aq.list;(enlist;1;2;3;4;5;6));
  z:eval (.aq.cond; .aq.funEnlist l;(enlist;(enlist;2; -1);(enlist;3; 100)); 200);
  w:eval (.aq.sums2;2;.aq.funEnlist l);
 eval (.aq.list;(enlist;(.aq.sqrt;.aq.funEnlist y);.aq.funEnlist z;.aq.funEnlist w))
 };

// verbatim code
 .aq.f:f; 
