#!/bin/sh
# gen_order_golden.sh: run the original Scala order analysis on the order
# test cases and write the expected results for
# tests/analysis/test_order_funs.q, test_order.q and test_join.q:
#   tests/analysis/order_golden.txt        one block per case of
#                                          tests/analysis/order_cases.txt
#   tests/analysis/order_funs_golden.txt   the flags of every UDF in
#                                          tests/inputs, order_udfs.a and
#                                          order_context.a
#   tests/analysis/order_cols_golden.txt   one block per case of
#                                          order_cols_cases.txt
#   tests/analysis/order_plans_golden.txt  the sort of every query plan
#                                          in tests/inputs
#   tests/analysis/join_golden.txt         one block per case of
#                                          join_cases.txt
#   tests/analysis/join_plans_golden.txt   every query plan with a join
#                                          in tests/inputs
# See tools/OrderDump.java (modes cases, funs, cols, plans, joincases and
# joinplans).
#
# Usage (from anywhere):   sh tools/gen_order_golden.sh [path/to/aquery.jar]
# Needs a JDK (javac and java). The jar defaults to tools/aquery.jar.

ROOT=$(cd "$(dirname "$0")/.." && pwd)
JAR=${1:-$ROOT/tools/aquery.jar}
BUILD=$(mktemp -d)

javac -d "$BUILD" -cp "$JAR" "$ROOT/tools/OrderDump.java" || exit 1

# paths in the goldens are relative to the aquery-q folder
cd "$ROOT" || exit 1
java -cp "$JAR:$BUILD" OrderDump cases tests/analysis/order_cases.txt \
    > tests/analysis/order_golden.txt
# every corpus program, in sorted order, then the two hand-written ones
# (find | sort | xargs: the paths have no spaces)
{ find tests/inputs -name '*.a' | sort; \
  echo tests/analysis/order_udfs.a; echo tests/analysis/order_context.a; } \
    | xargs java -cp "$JAR:$BUILD" OrderDump funs \
    > tests/analysis/order_funs_golden.txt
java -cp "$JAR:$BUILD" OrderDump cols tests/analysis/order_cols_cases.txt \
    > tests/analysis/order_cols_golden.txt
find tests/inputs -name '*.a' | sort \
    | xargs java -cp "$JAR:$BUILD" OrderDump plans \
    > tests/analysis/order_plans_golden.txt
java -cp "$JAR:$BUILD" OrderDump joincases tests/analysis/join_cases.txt \
    > tests/analysis/join_golden.txt
find tests/inputs -name '*.a' | sort \
    | xargs java -cp "$JAR:$BUILD" OrderDump joinplans \
    > tests/analysis/join_plans_golden.txt
rm -rf "$BUILD"
echo "wrote tests/analysis/order_*golden.txt and join_*golden.txt"
