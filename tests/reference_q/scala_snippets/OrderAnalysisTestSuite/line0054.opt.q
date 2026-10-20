// Translation begins here
f:{[x;y]
  z:eval (+; .aq.funEnlist x; (.aq.sum;.aq.funEnlist y));
 eval (*; .aq.funEnlist x; .aq.funEnlist z)
 };
