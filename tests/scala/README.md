# tests/scala — the original Scala test suites, copied as-is

From `aquery-master/src/test/scala/`. They are the specification for the
later stages. They cannot be run here (no sbt/Scala installed); they are
kept for reference and porting. Lexer coverage: none of them tests tokens
directly, which is why version 1 uses golden files from the jar instead.
