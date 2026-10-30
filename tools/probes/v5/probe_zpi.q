/ Is .z.pi (the console input hook) called for each typed line,
/ including lines starting with a backslash?
.z.pi:{[line]
  -1 "PI got: ",-3!line;
  r:@[value; line; {"value failed: ",x}];
  -1 "PI value: ",-3!r;
  };
-1 "hook set";
