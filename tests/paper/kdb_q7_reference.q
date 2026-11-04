/ kdb_q7_reference.q - Q7 written by hand in plain q by the paper's authors
/ (AQueryKDB src/test/financial/l_query/Q7_1.q), copied unchanged. The
/ paper test uses it to check what the compiled AQuery Q7 returns:
/     \l tests/paper/kdb_q7_reference.q
/     .kdb.q7[]

.kdb.q7:{
 alloc:10000.0;
 pxdata:select Id, TradeDate, ClosePrice from price where Id in stock10, 
  TradeDate >= -365 + max TradeDate;
 
 splitdata:select Id, SplitDate, SplitFactor from split where Id in stock10, 
   SplitDate >= -365 + max SplitDate;
 
 splitadj:0!select ClosePrice:first ClosePrice*prd SplitFactor by Id, TradeDate from 
   ej[`Id;pxdata;splitdata] where TradeDate < SplitDate;
 
 adjpxdata:`Id`TradeDate xasc pxdata lj `Id`TradeDate xkey splitadj;
 
 movingAvgs:update m21day:21 mavg ClosePrice, m5month:160 mavg ClosePrice by Id from adjpxdata;
 
 simulated:select result:alloc*prd ?[maxs m21day > m5month;?[m21day > m5month;1%ClosePrice;ClosePrice];1],
   stillInvested:last[m21day] > last m5month by Id
   from movingAvgs where (Id=prev[Id]) & 
    (
      ((prev[m5month] <= prev m21day)& m5month > m21day) |
      ((prev[m5month] >= prev m21day)& m5month < m21day)
    );
   
 latestPxs:select Id, ClosePrice from adjpxdata where TradeDate=max TradeDate;
 select stock_value:sum alloc^result * ?[stillInvested;ClosePrice;1] from latestPxs lj `Id xkey simulated
 }

