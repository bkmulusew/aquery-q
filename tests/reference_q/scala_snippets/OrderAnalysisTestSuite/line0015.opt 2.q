// Translation begins here
f:{[x]
  z:eval 2;
 eval (.aq.max;(*; (.aq.sums1;.aq.funEnlist z); 2))
 };

g:{[]
  res:eval (f;1);
 eval (+; .aq.funEnlist res; 3)
 };

h:{[x]
  res:eval (*; 2; (.aq.sum;.aq.funEnlist x));
 eval (.aq.pow; .aq.funEnlist res; 3)
 };

add:{[x;y]
 eval (+; .aq.funEnlist x; .aq.funEnlist y)
 };

myMax:{[x]
 eval (.aq.max;.aq.funEnlist x)
 };
