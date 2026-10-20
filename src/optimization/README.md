# src/optimization — query plan optimiser (planned, after analysis)

Empty in version 1. Will port:

- `aquery-master/src/main/scala/edu/nyu/aquery/optimization/BasicOptimizer.scala` (382 lines): simplifySort, filterBeforeSort, embedSort, simplifyEmbeddedSort, pushFiltersJoin, makeReorderFilter, sortToSortCols
- `aquery-master/src/main/scala/edu/nyu/aquery/optimization/Optimizer.scala` (33): optimiser interface
