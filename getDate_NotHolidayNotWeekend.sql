
 DECLARE @startDate date = '1/4/2018' --getdate()
 
 DECLARE  	  @localBOM		date = dateadd(MONTH,-1,dateadd(day,+1,eomonth(@startDate)))  -- 1st of month
			, @localEOM		date = eomonth(@startDate)
			-- when @startDate falls on a holiday or weekend, use previous business date
			, @BizDate date = (SELECT max([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) < @StartDate AND [ProcessDate] IS NOT NULL) 
			-- last day of previous full month
			, @PriorEOM		date = eomonth(dateadd(MONTH,-1,@startDate))   -- last day of previous month
			, @PriorBOM     date = dateadd(MONTH,-2,dateadd(day,+1,eomonth(@startDate))) -- first day of previous month
            -- last day of previous prior month		
			, @PreviousPriorEOM	 date = eomonth(dateadd(MONTH,-2,@startDate))   -- last day of previous month
		
			-- when @PriorBizDate falls on a holiday or weekend, use previous business date
			, @PriorBizDate date = (SELECT max([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) < dateadd(month,-1,@StartDate) AND [ProcessDate] IS NOT NULL) 

			-- when @localstartDate falls in prior month use min business day of current month not falling on a holiday or weekend
			SET @BizDate = CASE WHEN @BizDate < @localBOM 
									   THEN (SELECT min([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) > @PriorEOM AND [ProcessDate] IS NOT NULL) 
									   ELSE @BizDate END
	
			-- when @PriorBizDate falls in prior month use min business day of current month not falling on a holiday or weekend
			SET @PriorBizDate = CASE WHEN @PriorBizDate < @PriorBOM 
									   THEN (SELECT min([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) > @PreviousPriorEOM AND [ProcessDate] IS NOT NULL) 
									   ELSE @PriorBizDate END

Print '@StartDate:          ' + convert(varchar(10),@startDate,101)
Print '@BizDate:            ' + convert(varchar(10),@BizDate,101)
Print '@PriorBizDate        ' + convert(varchar(10),@PriorBizDate,101)
Print '     '
Print '@localBOM:           ' + convert(varchar(10),@localBOM,101)
Print '@localEOM:           ' + convert(varchar(10),@localEOM,101)
Print '     '
Print '@PriorBOM:           ' + convert(varchar(10),@PriorBOM,101)
Print '@PriorEOM:           ' + convert(varchar(10),@PriorEOM,101)
Print '     '
Print '@PreviousPriorEOM:   ' + convert(varchar(10),@PreviousPriorEOM,101)

--UPDATE DateDimensionSD
--Set ProcessDatePriorMth = @PriorBizDate
Select ProcessDatePriorMth = @PriorBizDate
from DateDimensionSD 
where [date] = @BizDate
--and yyyymm > 201712

SELECT [Date], ProcessDate, ProcessDatePriorMth = @PriorBizDate
from DateDimensionSD 
where [date] = @BizDate
--and yyyymm > 201712


		 -- SET @i  = 1
			--WHILE @i <= 25

			--	BEGIN
			--	SET @loopDate = (Select Date from #datedimeesults where [RowID] = @i)

			--	SET @i = @i + 1
			--	END



=======================================================================================================
-- Gets BOM, EOM, [MonthName Year], SID

SELECT DISTINCT BOM = d1.FirstDayOfMonth, EOM = d1.LastDayOfMonth, MonthYear = concat(d1.[MonthName],' ',convert(char(4),d1.[Year]))
, d2.[sid]
FROM     DateDimension d1
join (
SELECT ROW_NUMBER() OVER(ORDER BY FirstDayOfMonth ASC) AS sid, FirstDayOfMonth = max(FirstDayOfMonth)
from DateDimension
WHERE  (FirstDayOfMonth >= '8/1/2015') AND (LastDayOfMonth <= EOMONTH(GETDATE(), - 1)) OR
                  (LastDayOfMonth >= '8/1/2015') AND (FirstDayOfMonth <= EOMONTH(GETDATE(), - 1))
group by FirstDayOfMonth

) d2 on d1.FirstDayOfMonth = d2.FirstDayOfMonth
WHERE  (d1.FirstDayOfMonth >= '8/1/2015') AND (d1.LastDayOfMonth <= EOMONTH(GETDATE(), - 1)) OR
                  (d1.LastDayOfMonth >= '8/1/2015') AND (d1.FirstDayOfMonth <= EOMONTH(GETDATE(), - 1))
ORDER BY d2.[sid] DESC

=======================================================================================================







