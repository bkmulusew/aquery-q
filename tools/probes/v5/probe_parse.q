/ How do assignments look after parse in L?
show each parse each ("a:5";"a+:1";"a[0]:1";"1+1";"b:1;2";"3;";"f:{x}";"`t set 1";"::");
-1 "types of first: ",-3!{type first parse x} each ("a:5";"a+:1";"a[0]:1";"1+1");
-1 "first parse a:5 ~ (:)? ",-3!(:) ~ first parse "a:5";
-1 "Q.s of table:"; 1 .Q.s ([]x:1 2;y:`a`b);
-1 "Q.s of 2:"; 1 .Q.s 2;
-1 "Q.s of ::"; 1 .Q.s (::);
-1 "-3! of ::"; -1 -3!(::);
-1 "trap msg:"; -1 @[value;"'oops";{x}];
-1 "trap 1+`a:"; -1 @[value;"1+`a";{x}];
exit 0
