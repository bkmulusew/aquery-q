# src/runtime — q support library used by generated code

`base.q` is copied **unchanged** from
`aquery-master/src/main/resources/q/base.q`. The Scala compiler prints it
at the top of every compiled program.

Known L issue, deliberately not patched: line 201 defines
`.trg.kdbDeleteColsStmt:{[tbl;cols] ...}`. L does not allow a built-in name
(`cols`) as a parameter, so loading `base.q` in L stops there with `'type`
and the rest of the file is not loaded. Renaming the parameter (e.g. to
`cs`) fixes it. This has to be decided before the code-generation stage.
