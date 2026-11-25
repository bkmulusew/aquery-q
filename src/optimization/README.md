# src/optimization — query plan optimiser (planned, version 8)

Still empty. Version 8 will port:

- `aquery-master/src/main/scala/edu/nyu/aquery/optimization/BasicOptimizer.scala` (382 lines): simplifySort, filterBeforeSort, embedSort, simplifyEmbeddedSort, pushFiltersJoin, makeReorderFilter, sortToSortCols
- `aquery-master/src/main/scala/edu/nyu/aquery/optimization/Optimizer.scala` (33): optimiser interface

Each pass asks questions that the version 7 analysis (`src/analysis`)
already answers:

- sort passes (simplifySort, filterBeforeSort, embedSort,
  simplifyEmbeddedSort, sortToSortCols): `.aqc.order` (`colsToSort`,
  `hasOrderDependence`, `usesAggregate`, `hasSortBy`, `getSort`,
  `isPrefixSort`).
- pushFiltersJoin: `.aqc.join` (`hasJoin`, `annotate`, `placeFilter`).
- makeReorderFilter: `.aqc.order` (which conditions depend on row
  order, so they must keep their place).

Common rule-based rewrites are also planned on top of these (predicate
and projection pushdown, constant folding, predicate reordering, sort
elimination); their helpers will be added in version 8.
