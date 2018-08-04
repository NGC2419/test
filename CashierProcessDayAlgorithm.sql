USE [BDE_Data]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_calc_cashier_process_day_compare] 
	(
	@EndDate date
	)
AS
-- 
-- 
-- NOTE: PLEASE CONTACT S. DELANEY BEFORE CHANGING THIS PROGRAM
-- 
-- 
-- ===============================================================================================
-- Author:		   S. Delaney
-- Create date:    12/20/2016
-- Description:	   Algorithm calculates Cashier Process Days & Dates for Current & Prior Month (#694)
--				   Business rules: 1) Weekdays only with holidays & weekends excluded. 
--					2) When there's a variance in number of process days, replicate the 1rst process date x # of variance days. 
--				    3) Uses the same process day number for each month being compared. This means the process day number increments, 
--					   the first process *date* is duplicated for multiple process *days* at the beginning of the month contingent upon the variance value.
-- Example: 
-- Automates process day/compare date ​for use with day selected and corresponding day from the prior month as follows (2016):
-- Process Day   Nov Cal Day    Oct Cal Day     Dec Cal Day
-- 21                  1 Nov          3-Oct           1-Dec
-- 20                  2-Nov          3-Oct           2-Dec
-- 19                  3-Nov          4-Oct           5-Dec
-- 18                  4-Nov          5-Oct           6-Dec
-- 17                  7-Nov          6-Oct           7-Dec
-- 16                  8-Nov          7-Oct           8-Dec
--
-- IMPORTANT: IF sp_days_in_month changes you MUST change:  
--				  dbo.sp_cash_dashboard
--	    		  dbo.sp_days_in_month 
--				  dbo.sp_cash_dashboard_rolling_weeks
-- Modifications:  
-- ===============================================================================================
-- EXEC dbo.sp_calc_cashier_process_day_compare '9/30/2016'
-- DECLARE @endDate date = '11/30/2016'	 -- 20,20
-- DECLARE @endDate date = '10/31/2016'  -- 20, 21
-- DECLARE @endDate date = '9/30/2016'   -- 23, 22
SET NOCOUNT ON;

DECLARE @localEndDate date = @endDate
-- IMPORTANT: IF sp_days_in_month changes you MUST make corresponding changes to this #temp table
	CREATE TABLE #sp_days_in_month(
	[DaysInMonth] int,
	[DaysInPriorMonth] int,
	MondaysInMonth int,
	MondaysInPriorMonth int,
	StartDate date,
	EndDate date,
	PriorDay date,
	PriorMonth date,
	PriorMonthEnd date,
	DateSelected date,
	CurrentMonthName varchar(20),
	PriorMonthName varchar(20),
	CurrentMonthYear int,
	PriorMonthYear int
	) 

	INSERT INTO #sp_days_in_month
	exec sp_days_in_month @localEndDate
	SET @localEndDate = (select EndDate from #sp_days_in_month) 
	
	-- use local variables
	DECLARE @localStartDate			date = (select StartDate from #sp_days_in_month) 
	DECLARE  @PriorDay				date = (select PriorDay from #sp_days_in_month) 
			,@PriorMonth			date = (select PriorMonth from #sp_days_in_month) 
			,@PriorMonthEnd			date = (select PriorMonthEnd from #sp_days_in_month) 			
			,@StartOfMonth			date = (select StartDate from #sp_days_in_month) 
			,@DateSelected			date = (select DateSelected from #sp_days_in_month) 
			,@BusinessDay			date = @localEndDate
			,@CurrMthProcessDate	date
			,@CurrMthProcessDay		int
			,@CurrMthProcessDayCal	int
			,@PriorMthProcessDate	date
			,@PriorMthProcessDay	int
			,@PriorMthProcessDayCal int
	DECLARE  @MondaysInMonth		int = (select MondaysInMonth from #sp_days_in_month) 
			,@MondaysInPriorMonth	int = (select MondaysInPriorMonth from #sp_days_in_month) 

		-- retrieve entire population required for time slicing
		SELECT DISTINCT [Process Date]
			  ,[Wells Fargo Lockbox]
			  ,[Cash Room]
			  ,[LoanCare Payments]
			  ,[MoneyGram]
			  ,[GNMA I P&I]
			  ,[GNMA II P&I]
			  ,[Unidentified Checks]
			  ,[Payment Clearing]
			  ,[Lockbox (WF) Units]
			  ,[ACH (TX Capital) Units]
			  ,[Lockbox (WF)]
			  ,[ACH (TX Capital)]
			  ,[OTD]
			  ,[Recurring]
			  ,[Suspense]
			  ,[Accrued Late Fees]
			  ,[Escrow Advance]
			  ,[Recov Corp]
			  ,[Non-rec]
			  ,[Third-party Rec]
			  ,[Servicing Fee]
			  ,[Late Charges]
			  ,[ One Time Draft Fees]
			  ,[NSF Fees]
			  ,[Misc Fees]
			  ,[Total Anc Fee Income]
			  ,[OTD Fees (units)]
			  ,[NSF Fees (Units)]
			  ,[Payoffs Processed]
		  INTO #cashDash
		  FROM [dbo].[cash_dashboard]
		  WHERE convert(date,[Process Date]) BETWEEN convert(date,@PriorMonth) AND convert(date,@localenddate)
		  
	-- current month
	;WITH ProcessDaysCurrMonth AS
	(
	select YYYYMM = convert(varchar(6),[process date],112) 
	,TotalProcessDays = count(convert(date,[process date]))
	from cash_dashboard c
	JOIN DateDimension d on c.[Process Date] = d.[Date] and d.[isHoliday] = 0
	WHERE convert(date,c.[Process Date]) between convert(date,@StartOfMonth) AND EOMonth(convert(date,@StartofMonth))
	group by convert(varchar(6),[process date],112)
	)
	SELECT distinct p.YYYYMM
	,YYYYMMDD = convert(varchar(8),c.[process date],112) 
	,p.TotalProcessDays
	,ProcessDate = convert(date,c.[Process Date])
	INTO #ProcessDaysCurrMonth
	from ProcessDaysCurrMonth p
	JOIN #cashdash c on p.YYYYMM = convert(varchar(6),c.[process date],112) 
	JOIN DateDimension d on c.[Process Date] = d.[Date] and d.[isHoliday] = 0
	WHERE convert(date,c.[Process Date]) between convert(date,@StartofMonth) AND EOMonth(convert(date,@StartofMonth))

	SET @CurrMthProcessDayCal = (select distinct TotalProcessDays from #ProcessDaysCurrMonth)
	
	-- prior month
	;WITH ProcessDaysPriorMonth AS
	(
	select YYYYMM = convert(varchar(6),[process date],112) 
	,TotalProcessDays = count(convert(date,[process date]))
	from cash_dashboard c
	JOIN DateDimension d on c.[Process Date] = d.[Date] and d.[isHoliday] = 0
	WHERE convert(date,c.[Process Date]) between convert(date,@PriorMonth) AND EOMonth(convert(date,@PriorMonthEnd))
	group by convert(varchar(6),[process date],112)
	)
	SELECT distinct p.YYYYMM
	,YYYYMMDD = convert(varchar(8),c.[process date],112) 
	,p.TotalProcessDays
	,ProcessDate = convert(date,c.[Process Date])
	INTO #ProcessDaysPriorMonth 
	from ProcessDaysPriorMonth p
	JOIN #cashdash c on p.YYYYMM = convert(varchar(6),c.[process date],112) 
	JOIN DateDimension d on c.[Process Date] = d.[Date] and d.[isHoliday] = 0
	WHERE convert(date,c.[Process Date]) between convert(date,@PriorMonth) AND EOMonth(convert(date,@PriorMonthEnd))
	
	SET @PriorMthProcessDayCal = (select distinct TotalProcessDays from #ProcessDaysPriorMonth)

	DECLARE @TotalProcessDaysCurrMonth int = (select distinct TotalProcessDays from #ProcessDaysCurrMonth)
	DECLARE @TotalProcessDaysPriorMonth int = (select distinct TotalProcessDays from #ProcessDaysPriorMonth)
 	DECLARE @TotalProcessDaysVariance int = @TotalProcessDaysCurrMonth - @TotalProcessDaysPriorMonth 

		SELECT ROW_NUMBER() OVER (ORDER BY S.YYYYMMDD ASC) AS ProcessDay, S.* 
		INTO #ProcessDayC
		FROM (SELECT * FROM #ProcessDaysCurrMonth) AS S
		SELECT ROW_NUMBER() OVER (ORDER BY T.YYYYMMDD ASC) AS ProcessDay, T.*  
		INTO #ProcessDayP
		FROM (SELECT * FROM #ProcessDaysPriorMonth ) AS T
	
	-- process day variance = 0 for both months
	IF @TotalProcessDaysVariance = 0 
	BEGIN
		SELECT * INTO #ProcessDaysEqual
		FROM (
		SELECT * from #ProcessDayC
		UNION
		SELECT * from #ProcessDayP
		) x
			SELECT ProcessDayCurrMonth		= p1.ProcessDay
				  ,ProcessDateCurrMonth		= p1.ProcessDate
				  ,ProcessDayPriorMonth		= p2.ProcessDay
				  ,ProcessDatePriorMonth	= p2.ProcessDate
			 INTO #Processed0
			 FROM #ProcessDaysEqual p1
			 JOIN #ProcessDaysEqual p2 
			   ON p1.ProcessDay = p2.ProcessDay AND p1.ProcessDate <> p2.ProcessDate
			 WHERE convert(date,p1.ProcessDate) = @localEndDate
	END
	
	-- when < 0 there are more rows in prior month add 1rst day times the # of variance rows to current month
	IF @TotalProcessDaysVariance < 0 
		BEGIN
			DECLARE @i int
			SELECT YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate
			INTO #addCurr_1
	 		FROM #ProcessDaysCurrMonth
			SET @i = 0
			WHILE @i < abs(@TotalProcessDaysVariance) 
			BEGIN
				INSERT INTO #addCurr_1(YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate)
				SELECT DISTINCT YYYYMM,YYYYMMDD=min(YYYYMMDD),TotalProcessDays,ProcessDate = min(ProcessDate)
					FROM #ProcessDaysCurrMonth 
					GROUP BY YYYYMM,TotalProcessDays 
				SET @i = @i+1
			END
			SELECT ROW_NUMBER() OVER (ORDER BY T.YYYYMMDD ASC) AS ProcessDay
			,T.YYYYMM
			,T.YYYYMMDD
			,T.TotalProcessDays
			,T.ProcessDate
			INTO #ProcessDayCvar 
			FROM (SELECT * FROM #addCurr_1 ) AS T
		END
			
	-- when > 0 there are more rows in current month add 1rst day times the # of variance rows to prior month
	 IF @TotalProcessDaysVariance > 0 
		BEGIN
			DECLARE @j int
			SELECT YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate
			INTO #addPrior1
	 		FROM #ProcessDaysPriorMonth
			SET @j = 0
			WHILE @j < @TotalProcessDaysVariance
			BEGIN
				INSERT INTO #addPrior1(YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate)
				select DISTINCT YYYYMM,YYYYMMDD=min(YYYYMMDD),TotalProcessDays,ProcessDate = min(ProcessDate)
					FROM #ProcessDaysPriorMonth 
					GROUP BY YYYYMM,TotalProcessDays 
				SET @j = @j+1
			END
			SELECT ROW_NUMBER() OVER (ORDER BY T.YYYYMMDD ASC) AS ProcessDay
			,T.YYYYMM
			,T.YYYYMMDD
			,T.TotalProcessDays
			,T.ProcessDate
			INTO #ProcessDayPvar
			FROM (SELECT * FROM #addPrior1 ) AS T
		END

		-- insert adjustment row when there are more process days in the prior month
		IF object_id('tempdb.dbo.#ProcessDayCvar')	IS NOT NULL 
		BEGIN 
			INSERT INTO #ProcessDayCvar(ProcessDay,YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate)
			SELECT ProcessDay,YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate FROM #ProcessDayP
			SELECT ProcessDayCurrMonth		= p1.ProcessDay
				  ,ProcessDateCurrMonth		= p1.ProcessDate
				  ,ProcessDayPriorMonth		= p2.ProcessDay
				  ,ProcessDatePriorMonth	= p2.ProcessDate
			 INTO #ProcessedC
			 FROM #ProcessDayCvar p1
			 JOIN #ProcessDayCvar p2 
			   ON p1.ProcessDay = p2.ProcessDay AND p1.ProcessDate <> p2.ProcessDate
			 WHERE convert(date,p1.ProcessDate) = @localEndDate
		END
		
		-- insert adjustment row when there are more process days in the current month
		IF object_id('tempdb.dbo.#ProcessDayPvar')	IS NOT NULL 
		BEGIN 
			INSERT INTO #ProcessDayPvar(ProcessDay,YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate)
			SELECT ProcessDay,YYYYMM,YYYYMMDD,TotalProcessDays,ProcessDate FROM #ProcessDayC
			SELECT ProcessDayCurrMonth		= p1.ProcessDay
				  ,ProcessDateCurrMonth		= p1.ProcessDate
				  ,ProcessDayPriorMonth		= p2.ProcessDay
				  ,ProcessDatePriorMonth	= p2.ProcessDate
			 INTO #ProcessedP
			 FROM #ProcessDayPvar p1
			 JOIN #ProcessDayPvar p2 
			   ON p1.ProcessDay = p2.ProcessDay AND p1.ProcessDate <> p2.ProcessDate
			 WHERE convert(date,p1.ProcessDate) = @localEndDate
		END

			
	IF @TotalProcessDaysVariance = 0		
		BEGIN
			SET @CurrMthProcessDate		= (SELECT ProcessDateCurrMonth	FROM #Processed0)
			SET @CurrMthProcessDay		= (SELECT ProcessDayCurrMonth	FROM #Processed0)
			SET @PriorMthProcessDate	= (SELECT ProcessDatePriorMonth FROM #Processed0)
			SET @PriorMthProcessDay		= (SELECT ProcessDayPriorMonth	FROM #Processed0)
		END

	IF @TotalProcessDaysVariance < 0 
		BEGIN
			SET @CurrMthProcessDate		= (SELECT ProcessDateCurrMonth	FROM #ProcessedC)
			SET @CurrMthProcessDay		= (SELECT ProcessDayCurrMonth	FROM #ProcessedC)
			SET @PriorMthProcessDate	= (SELECT ProcessDatePriorMonth FROM #ProcessedC)
			SET @PriorMthProcessDay		= (SELECT ProcessDayPriorMonth	FROM #ProcessedC)
		END

	IF @TotalProcessDaysVariance > 0 
		BEGIN
			SET @CurrMthProcessDate		= (SELECT ProcessDateCurrMonth	FROM #ProcessedP)
			SET @CurrMthProcessDay		= (SELECT ProcessDayCurrMonth	FROM #ProcessedP)
			SET @PriorMthProcessDate	= (SELECT ProcessDatePriorMonth FROM #ProcessedP)
			SET @PriorMthProcessDay		= (SELECT ProcessDayPriorMonth	FROM #ProcessedP)
		END

	SELECT	[ProcessDay]						= @CurrMthProcessDay
			,[ProcessDayPriorMonth]				= @PriorMthProcessDay
			,[MondaysInMonth]					= @MondaysInMonth
			,[MondaysInPriorMonth]				= @MondaysInPriorMonth
			,CurrMthProcessDate					= @CurrMthProcessDate
			,PriorMthProcessDate				= @PriorMthProcessDate
			,[TotalProcessDays]					= (CASE WHEN DaysInPriorMonth > DaysInMonth THEN DaysInPriorMonth ELSE DaysInMonth END)
			,[CurrMthTotProcessCalendarDays]	= @CurrMthProcessDayCal
			,[PriorMthTotProcessCalendarDays]	= @PriorMthProcessDayCal
	FROM #sp_days_in_month

		IF object_id('tempdb.dbo.#sp_days_in_month')		IS NOT NULL drop table dbo.#sp_days_in_month
		IF object_id('tempdb.dbo.#cashdash')				IS NOT NULL drop table dbo.#cashdash
		IF object_id('tempdb.dbo.#ProcessDaysCurrMonth')	IS NOT NULL drop table dbo.#ProcessDaysCurrMonth
		IF object_id('tempdb.dbo.#ProcessDaysPriorMonth')	IS NOT NULL drop table dbo.#ProcessDaysPriorMonth
		IF object_id('tempdb.dbo.#addCurr_1')				IS NOT NULL drop table dbo.#addCurr_1
		IF object_id('tempdb.dbo.#addPrior1')				IS NOT NULL drop table dbo.#addPrior1
		IF object_id('tempdb.dbo.#ProcessDaysEqual')		IS NOT NULL drop table dbo.#ProcessDaysEqual
		IF object_id('tempdb.dbo.#ProcessDayC')				IS NOT NULL drop table dbo.#ProcessDayC
		IF object_id('tempdb.dbo.#ProcessDayCvar')			IS NOT NULL drop table dbo.#ProcessDayCvar
		IF object_id('tempdb.dbo.#ProcessDayP')				IS NOT NULL drop table dbo.#ProcessDayP
		IF object_id('tempdb.dbo.#ProcessDayPvar')			IS NOT NULL drop table dbo.#ProcessDayPvar
		IF object_id('tempdb.dbo.#ProcessDateP')			IS NOT NULL drop table dbo.#ProcessDateP
		IF object_id('tempdb.dbo.#ProcessDatesC')			IS NOT NULL drop table dbo.#ProcessDatesC
		IF object_id('tempdb.dbo.#ProcessDatesP')			IS NOT NULL drop table dbo.#ProcessDatesP
		IF object_id('tempdb.dbo.#Processed0')				IS NOT NULL drop table dbo.#Processed0
		IF object_id('tempdb.dbo.#ProcessedC')				IS NOT NULL drop table dbo.#ProcessedC
		IF object_id('tempdb.dbo.#ProcessedP')				IS NOT NULL drop table dbo.#ProcessedP
GO
