.kdb.f:{[]
  x:-3+100*2;
  y:x xexp 3;
  l:1 2 3 4 5 6;
  z:200^(2 3!-1 100) l;
  w:2 msum l;
  (sqrt y; z; w)};
