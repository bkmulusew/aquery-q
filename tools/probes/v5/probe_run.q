/ Compile AQuery with .aqc.compile, then run the q code in L.
.aqc.root:".";
system "l aquery.q";
system "l /tmp/aq_base_l.q";
-1 "base loaded, .aq names: ",string count key `.aq;
t:([] a:1 2 3; b:10 20 30);
/ try[label; aquery] compiles, prints the code, runs it two ways.
try:{[label; src]
  -1 "---- ",label;
  code:@[.aqc.compile; src; {"COMPILE FAILED: ",x}];
  -1 code;
  r1:@[value; code; {"value failed: ",x}];
  -1 "value result type ",(string type r1),":";
  show r1;
  (hsym `$"/tmp/aq_probe_q.q") 0: "\n" vs code;
  r2:@[{system "l /tmp/aq_probe_q.q"; `loaded}; ::; {"\\l failed: ",x}];
  -1 "\\l result: ",-3!r2;
  };
try["simple select"; "SELECT a, b FROM t WHERE a > 1"];
try["group by"; "SELECT a, sum(b) AS s FROM t GROUP BY a"];
try["assuming asc"; "SELECT a, sums(b) AS r FROM t ASSUMING ASC a"];
try["create insert select"; "CREATE TABLE s (id INT, p INT)\nINSERT INTO s VALUES(1, 10)\nINSERT INTO s VALUES(2, 20)\nINSERT INTO s VALUES(1, 5)\nSELECT id, sum(p) AS tot FROM s GROUP BY id"];
try["update"; "UPDATE t SET b = b + 1 WHERE a > 1\nSELECT * FROM t"];
try["delete"; "DELETE FROM t WHERE a = 1\nSELECT * FROM t"];
try["udf"; "FUNCTION f(x) { x * 2 }\nSELECT f(b) AS d FROM t"];
try["join"; "SELECT t.a, s.p FROM t INNER JOIN s ON t.a = s.id"];
try["parse error"; "SELECT FROM"];
-1 "Q functions: ",-3!key `.Q;
exit 0
