# tests/ast — planned for version 2

The Scala project has no separate AST test suite: AST shapes are checked
inside `ParserTestSuite.scala` (expected values such as
`BinExpr(Plus, IntLit(2), ...)`). Those expected trees will be ported here.
