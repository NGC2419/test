USE [BDE_Data]
GO
	DECLARE @localEndDate date = '5/30/2017'
	
	CREATE TABLE #dates(
	[DaysInMonth] int,
	[DaysInPriorMonth] int,
	StartDate date,
	EndDate date,
	PriorDay date,
	PriorMonth date,
	PriorMonthEnd date,
	DateSelected date,
	CurrentMonthName varchar(20),
	PriorMonthName varchar(20),
	CurrentMonthYear int,
	PriorMonthYear int,
	MondaysInMonth int,
	MondaysInPriorMonth int
	) 

	INSERT INTO #dates
			select 
			[DaysInMonth],
			[DaysInPriorMonth],
			StartDate,
			EndDate,
			PriorDay,
			PriorMonth,
			PriorMonthEnd,
			DateSelected,
			CurrentMonthName,
			PriorMonthName,
			CurrentMonthYear,
			PriorMonthYear,
			MondaysInMonth,
			MondaysInPriorMonth
			from udf_2monthslice (@localEndDate)
	SET @localEndDate = (select EndDate from #dates) 

 	-- use local variables
	DECLARE @localStartDate			date = (select StartDate from #dates) 
	DECLARE  @PriorDay				date = (select PriorDay from #dates) 
			,@PriorMonth			date = (select ProcessDatePriorMth from DateDimension where convert(date,[Date]) = @localEndDate)
			,@PriorMonthEnd			date = (select PriorMonthEnd from #dates) 			
			,@StartOfMonth			date = (select StartDate from #dates) 
			,@DateSelected			date = (select DateSelected from #dates) 
			,@MondaysInMonth		int = (select MondaysInMonth from #dates) 
			,@MondaysInPriorMonth	int = (select MondaysInPriorMonth from #dates) 
			,@BusinessDay			date = @localEndDate
			,@CurrMthProcessDate	date = (select EndDate from #dates)
			,@CurrMthProcessDay		int = (select ProcessDay from DateDimension where convert(date,[Date]) = @localEndDate)
			,@CurrMthProcessDayCal	int = (select NbrProcessDays from DateDimension where convert(date,[Date]) = @localEndDate)
			,@PriorMthProcessDate	date = (select ProcessDatePriorMth from DateDimension where convert(date,[Date]) = @localEndDate)
			,@PriorMthProcessDay	int = (select ProcessDayPriorMth from DateDimension where convert(date,[Date]) = @localEndDate)
			,@PriorMthProcessDayCal int = (select NbrProcessDaysPriorMth from DateDimension where convert(date,[Date]) = @localEndDate)

			,@ProcessDay			int = (select ProcessDay from DateDimension where convert(date,[Date]) = @localEndDate)
			,@ProcessDayPriorMonth	int = (select ProcessDayPriorMth from DateDimension where convert(date,[Date]) = @localEndDate)

			,@TotalProcessDays		int = (select NbrProcessDays from DateDimension where convert(date,[Date]) = @localEndDate)
			,@TotalProcessDaysPrev	int = (select NbrProcessDaysPriorMth from DateDimension where convert(date,[Date]) = @localEndDate)
			,@CurrMthTotProcessCalendarDays int	 = (select NbrProcessDays from DateDimension where convert(date,[Date]) = @localEndDate)
			,@PriorMthTotProcessCalendarDays int = (select NbrProcessDaysPriorMth from DateDimension where convert(date,[Date]) = @localEndDate)

		 	select [Date]
			,[ProcessDay] =  ROW_NUMBER() OVER (ORDER BY [Date])
			INTO #currMonth
		 	from DateDimension 
			WHERE isWeekend = 0 
			  AND IsHoliday = 0 
			  AND [Year] = DatePart(YYYY,EOMonth(@localEndDate)) AND [Month] = DATEPART(MM,EOMonth(@localEndDate)) 

			select [Date]
			,[ProcessDay] =  ROW_NUMBER() OVER (ORDER BY [Date])
			INTO #prevMonth
			from DateDimension
			WHERE isWeekend = 0 
			  AND IsHoliday = 0 
			  AND [Year] = DatePart(YYYY,@PriorMonthEnd) AND [Month] = DATEPART(MM,@PriorMonthEnd) 


		/************************  DIM TABLES  ******************************/

		SELECT [EscrowAdvanceBalance_ProcessDay]	= sum(isnull(e1.es_adv_ba,0))		 
			 , [EscrowBalance_ProcessDay]			= sum(isnull(e1.es_ba,0))			 
	 		 , [EscrowAdvanceDisb_ProcessDay]		= max(isnull(e2.EscrowAdvanceDisb,0))
		  into #escrow_Day
		  FROM [BDESime].[dbo].[dim_loan] l		
		  INNER JOIN [bde_data].[dbo].ufngetmax_escrow(@CurrMthProcessDate) e1 on l.[ln_no] = e1.[ln_no]
		  OUTER APPLY (
			SELECT DISTINCT EscrowAdvanceDisb = abs(sum(e.dsb_am)) -- disbursements
			  FROM [bde_data].[dbo].[escrow_disb_tran] e (NOLOCK)
			 WHERE e.dsb_trans_cd = '168' 
			   AND convert(date,e.dsb_trans_dt)  = convert(date,@CurrMthProcessDate)
			) e2
			WHERE l.ln_1st_prin_ba> 0 and @CurrMthProcessDate between convert(date,l.valid_from_date) and convert(date,l.valid_through_date)
 		 
 
		SELECT [EscrowAdvanceBalance_PriorDay]		= sum(isnull(pd1.es_adv_ba,0))		 
			 , [EscrowBalance_PriorDay]				= sum(isnull(pd1.es_ba,0))			 
	 		 , [EscrowAdvanceDisb_PriorDay]			= max(isnull(pd2.EscrowAdvanceDisb,0))
		  into #escrow_PriorDay
		  FROM [BDESime].[dbo].[dim_loan] l		
		  INNER JOIN [bde_data].[dbo].ufngetmax_escrow(@PriorDay) pd1 on l.[ln_no] = pd1.[ln_no]
 		 OUTER APPLY (
			SELECT DISTINCT EscrowAdvanceDisb = abs(sum(e.dsb_am)) 
			  FROM [bde_data].[dbo].[escrow_disb_tran] e (NOLOCK)
			 WHERE e.dsb_trans_cd = '168' 
			   AND convert(date,e.dsb_trans_dt)  = convert(date,@PriorDay)
			) pd2
			WHERE l.ln_1st_prin_ba> 0 and @CurrMthProcessDate between convert(date,l.valid_from_date) and convert(date,l.valid_through_date)
 
		SELECT [EscrowAdvanceBalance_PriorMonthCompare]		= sum(isnull(pm1.es_adv_ba,0))		 
			 , [EscrowBalance_PriorMonthCompare]			= sum(isnull(pm1.es_ba,0))			 
	 		 , [EscrowAdvanceDisb_PriorMonthCompare]		= max(isnull(pm2.EscrowAdvanceDisb,0))
		  into #escrow_PriorMonthCompare
		  FROM [BDESime].[dbo].[dim_loan] l		
		  INNER JOIN [bde_data].[dbo].ufngetmax_escrow(@PriorMthProcessDate) pm1 on l.[ln_no] = pm1.[ln_no]
 		 OUTER APPLY (
			SELECT DISTINCT EscrowAdvanceDisb = abs(sum(e.dsb_am)) 
			  FROM [bde_data].[dbo].[escrow_disb_tran] e (NOLOCK)
			 WHERE e.dsb_trans_cd = '168' 
			   AND convert(date,e.dsb_trans_dt)  = convert(date,@PriorMthProcessDate)
			) pm2
			WHERE l.ln_1st_prin_ba> 0 and @PriorMthProcessDate between convert(date,l.valid_from_date) and convert(date,l.valid_through_date)

		SELECT [EscrowAdvanceBalance_PriorMonth]	= sum(isnull(d1.es_adv_ba,0))		 
			 , [EscrowBalance_PriorMonth]			= sum(isnull(d1.es_ba,0))			 
	 		 , [EscrowAdvanceDisb_PriorMonth]		= max(isnull(d2.EscrowAdvanceDisb,0))
		  into #escrow_PriorMonth
		  FROM [BDESime].[dbo].[dim_loan] l		
		  INNER JOIN [bde_data].[dbo].ufngetmax_escrow(@CurrMthProcessDate) d1 on l.[ln_no] = d1.[ln_no]
 		 OUTER APPLY (
			SELECT DISTINCT EscrowAdvanceDisb = abs(sum(e.dsb_am)) 
			  FROM [bde_data].[dbo].[escrow_disb_tran] e (NOLOCK)
			 WHERE e.dsb_trans_cd = '168' 
			   AND convert(date,e.dsb_trans_dt) BETWEEN convert(date,DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrMthProcessDate)- 1, 0)) AND convert(date,@CurrMthProcessDate)
			) d2
			WHERE l.ln_1st_prin_ba> 0 and @CurrMthProcessDate between convert(date,l.valid_from_date) and convert(date,l.valid_through_date)
			
			select e.*, e2.*,e3.*, e4.*	from #escrow_Day e Outer apply #escrow_PriorDay e2, #escrow_PriorMonth e3, #escrow_PriorMonthCompare e4


drop table #escrow_Day1,#escrow_PriorDay1,#escrow_PriorMonth1,#escrow_PriorMonthCompare1,#escrow_Day,#escrow_PriorDay,#escrow_PriorMonth,#escrow_PriorMonthCompare,#dates,#currMonth,#prevMonth
