// Translation begins here
.aq.show `lineitem set ([]l_orderkey:"j"$();l_partkey:"j"$();l_suppkey:"j"$();l_linenumber:"j"$();l_quantity:"f"$();l_extendedprice:"f"$();l_discount:"f"$();l_tax:"f"$();l_returnflag:"s"$();l_linestatus:"s"$();l_shipdate:"s"$();l_commitdate:"s"$();l_receiptdate:"s"$();l_shipinstruct:"s"$();l_shipmode:"s"$();l_comment:"s"$());

.aq.show .aq.load[hsym `$"/Users/tianxin/projects/nyu/ms1/research/dbtunning_experiements/data_generation/tpch/data_sf2/lineitem.tbl";"|";`lineitem];

.aq.show `orders set ([]o_orderkey:"j"$();o_custkey:"j"$();o_orderstatus:"s"$();o_totalprice:"f"$();o_orderdate:"s"$();o_orderpriority:"s"$();o_clerk:"s"$();o_shippriority:"j"$();o_comment:"s"$());

.aq.show .aq.load[hsym `$"/Users/tianxin/projects/nyu/ms1/research/dbtunning_experiements/data_generation/tpch/data_sf2/orders.tbl";"|";`orders];
