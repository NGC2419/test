DECLARE @TotalProcessDaysCurrMonth int = (select distinct TotalProcessDays from #ProcessDaysCurrMonth)
	DECLARE @TotalProcessDaysPriorMonth int = (select distinct TotalProcessDays from #ProcessDaysPriorMonth)
 	DECLARE @TotalProcessDaysVariance int = @TotalProcessDaysCurrMonth - @TotalProcessDaysPriorMonth 
	
	-- when < 0 there are more rows in prior month so add rows to current month
	IF @TotalProcessDaysVariance < 0 
	BEGIN
		declare @i int
		select YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate
		into #addCurr
	 	from #ProcessDaysCurrMonth
		set @i = 0
		WHILE @i < abs(@TotalProcessDaysVariance) 
		BEGIN
			insert into #addCurr(YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate)
			select DISTINCT YYYYMM,YYYYMMDD=min(YYYYMMDD),TotalProcessDays,ProcessDate = min(ProcessDate) from #ProcessDaysCurrMonth Group by YYYYMM,TotalProcessDays 
			set @i = @i+1
		END 
	END
