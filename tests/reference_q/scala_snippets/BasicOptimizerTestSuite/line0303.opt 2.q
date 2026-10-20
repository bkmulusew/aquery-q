// Translation begins here
add:{[x;y]
 eval (+; .aq.funEnlist x; .aq.funEnlist y)
 };

myAvg:{[x]
 eval (%; (.aq.sum;.aq.funEnlist x); (.aq.count;.aq.funEnlist x))
 };
