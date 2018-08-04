USE [BDE_Data]
GO

/****** Object:  StoredProcedure [dbo].[sp_portfolio_summary_rpt_scott]    Script Date: 12/8/2016 3:23:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_portfolio_summary_rpt_scott]
  ( @enddate datetime
   ,@Client_Code varchar(MAX)
   ,@State varchar(3) 
   ,@post_pre int
  ) 
AS
-- ======================================================================
-- Author:			SD
-- Create date:		6/23/2016
-- Description:		Daily Portfolio Summary Report
--					Renders a month of loan detail
--
-- Modified date:  	6/24/2016 Algorithm for xfersInOut = reinstated - REO - unidentified + NSF
--					7/11/2016 Added logic for SSRS dropdown listbox for State
--				    7/14/2016 Added new function call for subservicing
--					10/3/2016 remove unused code
--					10/17/2016 added state logic 
-- ======================================================================
-- exec [dbo].[sp_portfolio_summary_rpt_scott] '8/5/2016','all','ct', 0
--DECLARE @enddate as datetime = '10/14/2016', @Client_Code varchar(200) = 'all', @State varchar(200) = 'all'

DECLARE @localEndDate as datetime = @enddate
,@localState varchar(3) = @State
,@localClientCode varchar(MAX)
,@all char(3) = 'All'

    DECLARE @local_post_pre  int
	SELECT  @local_post_pre = @post_pre
	--SELECT @local_post_pre = 0

	select @localClientCode = coalesce(@localClientCode+',','') + client from (select distinct client from investor_client) t
	select @localClientCode = CASE WHEN @Client_Code = @all THEN @localClientCode ELSE @Client_Code END

	select distinct l.ln_no, l.iv_id, l.iv_cat_cd, iv_nm = ic.investor
	INTO #ClientLoans
 	FROM dbo.ufnGetMax_loan(@localEndDate) l
	INNER JOIN investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 
	JOIN  dbo.property p on l.ln_no = p.[ln_no]
	WHERE p.[pr_alpha_state_cd] LIKE (CASE @localState WHEN 'All' THEN '%' ELSE @localState END)
	

	/* Delinquency buckets */
	select d.[Loan Date] 
		   ,[Status] = 	CASE WHEN @local_post_pre = 0 THEN [MTH STATUS NAME] ELSE 
						    CASE 
								WHEN d.[MSP DLQ STATUS] = '1' THEN '30 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = '2' THEN '60 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = '3' THEN '90 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = '4' THEN '120+ Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = 'A' THEN 'Pre-30 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = 'B' THEN 'Pre-30 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = 'C' THEN 'Pre-30 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = 'D' THEN 'Pre-30 Days Delinquent'
								WHEN d.[MSP DLQ STATUS] = 'P' THEN 'Prepaid or Current'
							ELSE 'NO DESCRIPTION SET' END
						END  				
		   ,[Loans] = count(d.[Loan Number]) 
		   into #buckets
		   FROM #ClientLoans c  
		   INNER JOIN bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
	 -- from first of month thru @localEndDate
	where convert(date,d.[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
	and d.[FIRST PRINCIPAL BALANCE] > 0
	and d.[MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent')
	group by d.[Loan Date], d.[MTH STATUS NAME], [MSP DLQ STATUS]

	/* Pivot into Loan Status columns */
		SELECT  * into #Status
					FROM (
						SELECT 
							[status] 
							, [Loan Date] 
							, [COUNT] = loans
						FROM #buckets
					) as s
					PIVOT
					(
						Sum([count])
						FOR [Status] IN ([Pre-30 Days Delinquent],[Prepaid or Current],[30 Days Delinquent],[60 Days Delinquent],[90 Days Delinquent],[120+ Days Delinquent])
					)AS pvt


	/* Real Estate Owned Loans  (REO)   */
				Select d.[loan date]
					  , REO = ISNULL(Count(*) ,0)				
				 into #REO
				 FROM #ClientLoans c  INNER JOIN   bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
				  where convert(date,d.[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
					 and  d.[FIRST PRINCIPAL BALANCE] <> 0 and  d.proper_status  like '%REO%' --[MAN CODE] = 'R'
				  group by d.[LOAN DATE]


	/* Active Loans */
			Select  d.[loan date]
					,[Active] = Count(*) 				
				into #Active
				 FROM #ClientLoans c  INNER JOIN   bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where convert(date,d.[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
					and  d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status not like 'REO%'
				  group by d.[LOAN DATE]

	/* FHA Pre-Conveyance */
			Select  d.[loan date]
					,[FHAPreConveyance] = Count(*) 				
				into #FHApreConveyance
				 FROM #ClientLoans c  INNER JOIN   bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where convert(date,d.[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
					and  d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status = 'FHA Pre-Conveyance'
				  group by d.[LOAN DATE]

	/* Bankruptcy */
			Select  d.[loan date]
					,[Bankruptcy] = Count(*) 				
				into #Bankruptcy
				 FROM #ClientLoans c  INNER JOIN   bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where convert(date,[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
					and  d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status = 'Bankruptcy'
				  group by d.[LOAN DATE]


	/* Foreclosure */
			Select  d.[loan date]
					,[Foreclosure] = Count(*) 				
				into #Foreclosure
				 FROM #ClientLoans c  INNER JOIN   bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where convert(date,[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
					and d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status = 'Foreclosure'
				  group by d.[LOAN DATE]
		
	/* Payoffs */
	SELECT Payoffs = isnull(count(tt.ln_no),0)
		,PayoffDate = ln_pif_dt
		INTO #Payoffs
 	FROM #ClientLoans c  INNER JOIN  [dbo].[loan] tt ON c.[ln_no] = tt.[ln_no]
	INNER JOIN (
		 SELECT l.ln_no, MAX(load_date) AS MaxDateTime
		 FROM #ClientLoans c  INNER JOIN  dbo.loan l ON c.[ln_no] = l.[ln_no]
		 WHERE l.load_date <= (DATEADD(day, DATEDIFF(day, -1, @localEnddate), 0))
		 GROUP BY l.ln_no) groupedtt 
		 ON tt.ln_no = groupedtt.ln_no
		AND tt.load_date = groupedtt.MaxDateTime 
		AND tt.delta_file_byte in ('A','C')
	 where convert(date,ln_pif_dt) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
	 group by ln_pif_dt

	 
  /* New Loans */
  SELECT [Loan Date] = CAST([NEW LOAN SETUP DATE] as date)  
			,NewLoans = isnull(count(*),0)
			INTO #NewLoans
			FROM #ClientLoans c  INNER JOIN dbo.loan l ON c.[ln_no] = l.[ln_no]
			LEFT JOIN BDESIME.[dbo].[original_loan] ol ON ol.[LOAN NUMBER] = l.ln_no
			WHERE   CAST([NEW LOAN SETUP DATE] as date) Between  DATEADD(mm, DATEDIFF(mm, 0, @localenddate), 0) and @localenddate	
		 and l.delta_file_byte = 'A'
			group by [NEW LOAN SETUP DATE]


	/* SSRS Resultset */
				select DISTINCT [LoanDate]		= s.[LOAN DATE]
					,[NewLoans]					= isnull(nl.[NewLoans],0)
					,[TotalLoans]				= isnull(0,0)   
					,[Payoffs]					= isnull(p.[Payoffs],0)
					,[Active]					= isnull(a.[Active],0)
					,[Prepaid or Current]		= isnull(s.[Prepaid or Current],0)
					,pct_prepaid				= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(s.[Prepaid or Current],0) / isnull(a.[Active],1)),1) 
					,[Current Month]			= ISNULL(s.[Pre-30 Days Delinquent],0)
					,pct_current				= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(s.[Pre-30 Days Delinquent],0) / isnull(a.[Active],1)),1) 

					,[30 Days Delinquent]		= ISNULL(s.[30 Days Delinquent],0)
					,pct_30						= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(s.[30 Days Delinquent],0) / isnull(a.[Active],1)),1) 

					,[60 Days Delinquent]		= ISNULL(s.[60 Days Delinquent],0)
					,pct_60						= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(s.[60 Days Delinquent],0) / isnull(a.[Active],1)),1) 
					,[90 Days Delinquent]		= ISNULL(s.[90 Days Delinquent],0)
					,pct_90						= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(s.[90 Days Delinquent],0) / isnull(a.[Active],1)),1) 
					,[120+ Days Delinquent]		= ISNULL(s.[120+ Days Delinquent],0) - isnull(r.[REO],0)
					,pct_120					= ISNULL(CONVERT(DECIMAL(10,2),100.0 * (isnull(s.[120+ Days Delinquent],0) - isnull(r.[REO],0)) / isnull(a.[Active],1)),1) 
					,[REO]						= isnull(r.[REO],0)
					,pct_REO					= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(r.[REO],0) / isnull(a.[Active],1)),1) 
					,[Foreclosure]				= ISNULL(f.Foreclosure,0)
					,[pct_Foreclosure]			= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(f.[Foreclosure],0) / isnull(a.[Active],1)),1) 
					,[Bankruptcy]				= ISNULL(b.bankruptcy,0)
					,[pct_Bankruptcy]			= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(b.[Bankruptcy],0) / isnull(a.[Active],1)),1) 
					,[FHA_PreConveyance]		= ISNULL(fha.[FHApreConveyance],0)
					,[pct_FHA_PreConveyance]	= ISNULL(CONVERT(DECIMAL(10,2),100.0 * isnull(fha.[FHAPreConveyance],0) / isnull(a.[Active],1)),1) 
					,Client						= @Client_Code
			from #Status s
			left join #REO r					on s.[LOAN DATE] = r.[LOAN DATE]
			left join #Active a					on s.[LOAN DATE] = a.[LOAN DATE]
			left join #NewLoans nl				on s.[LOAN DATE] = nl.[LOAN DATE]
			left join #Payoffs p				on s.[LOAN DATE] = p.[PayoffDate]
			left join #Bankruptcy b				on s.[LOAN DATE] = b.[LOAN DATE]
			left join #Foreclosure f			on s.[LOAN DATE] = f.[LOAN DATE]
			left join #FHApreConveyance fha		on s.[LOAN DATE] = fha.[LOAN DATE]
			order by s.[LOAN DATE]

	drop table #buckets
	drop table #Status
	drop table #REO
	drop table #Active
	drop table #Payoffs
	drop table #NewLoans
	drop table #FHApreConveyance
	drop table #Foreclosure
	drop table #Bankruptcy
	drop table #ClientLoans

GO


