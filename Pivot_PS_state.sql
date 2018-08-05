USE [BDE_Data]
GO

/****** Object:  StoredProcedure [dbo].[sp_portfolio_summary_by_State]    Script Date: 11/18/2017 10:34:18 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_portfolio_summary_by_State]
  ( @enddate date
   ,@Client_Code varchar(MAX)
   ,@State varchar(MAX) 
  ) 
AS
-- =====================================================================================================================
-- Author:			SDelaney
-- Create date:		12/23/2016
-- Description:		Daily Portfolio Summary by State
-- Modified date:  	11/15/2017 SD re-engineered due to temp investor IDs in delinquency_snapshot reporting table 
--							      skewing results across reports
--					10/16/2017 SD modified parms for multi-value selection
-- =====================================================================================================================
-- declare @enddate date = '11/14/2017',@client_code varchar(max) = 'ssv801', @State varchar(max) = 'AK, AL, AR, AZ, CA, CO, CT, DC, DE, FL, GA, HI, IA, ID, IL, IN, KS, KY, LA, MA, MD, ME, MI, MN, MO, MS, MT, NC, ND, NE, NH, NJ, NM, NV, NY, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VA, VT, WA, WI, WV, WY'
  	 DECLARE @localEndDate		datetime	 = @enddate
			,@localState		varchar(MAX) = @State
			,@localClientCode	varchar(MAX) = @Client_Code

		  Select distinct [loan date] = convert(date,d.[loan date])
				,d.[Loan Number]
				,ic.client
				,d.[investor id] 
				,d.iv_cat_cd
				,d.proper_status
				,d.[MTH STATUS NAME]
				,d.[FIRST PRINCIPAL BALANCE]
				,[State] = p.[property alpha state code]
		 into #delinquency_snapshot
		FROM bdesime.dbo.delinquency_snapshot d (nolock) 
		INNER JOIN investor_client ic (nolock) on ic.inv_id = d.[investor id] and ic.inv_cat = d.[iv_cat_cd] 
		and d.[investor id] not like 't%'  
	    LEFT JOIN  dbo.ufnGetMax_loan(@localEndDate) l on d.[investor id] = l.iv_id and d.iv_cat_cd = l.iv_cat_cd 
	    LEFT JOIN bdesime.dbo.property p (nolock) on d.[loan number] = p.[loan number] 
	WHERE p.[property alpha state code] IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localState, ',') b) 
  	  AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 
	  AND convert(date,d.[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
	  and d.[FIRST PRINCIPAL BALANCE] <> 0 
	 					  
	/* Delinquency buckets */
	select d.[Loan Date] 
		   ,[Status] = d.[MTH STATUS NAME]
		   ,[Loans] = count(d.[Loan Number]) 
		   into #buckets
		   FROM #delinquency_snapshot d 
	 -- from first of month thru @localEndDate
	where d.[FIRST PRINCIPAL BALANCE] > 0
	and d.[MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent')
	group by d.[Loan Date], d.[MTH STATUS NAME]


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
			FROM #delinquency_snapshot d 
					 where  d.proper_status  like '%REO%'
				  group by d.[LOAN DATE]

	/* Active Loans */
			Select  d.[loan date]
					,[Active] = isnull(Count(*) ,0)
			into #Active
				FROM #delinquency_snapshot d 
				  where d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status not like '%REO%'
				  group by convert(date,d.[LOAN DATE])

	/* FHA Pre-Conveyance */
			Select  d.[loan date]
					,[FHAPreConveyance] = Count(*) 				
				into #FHApreConveyance
				 FROM #delinquency_snapshot d 
				  where  d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status = 'FHA Pre-Conveyance'
				  group by d.[LOAN DATE]

	/* Bankruptcy */
			Select  d.[loan date]
					,[Bankruptcy] = Count(*) 				
				into #Bankruptcy
				  FROM #delinquency_snapshot d 
				  where  d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status = 'Bankruptcy'
				  group by d.[LOAN DATE]

	/* Foreclosure */
			Select  d.[loan date]
					,[Foreclosure] = Count(*) 				
				into #Foreclosure
				 FROM #delinquency_snapshot d 
				  where d.[FIRST PRINCIPAL BALANCE] > 0 
					and d.proper_status = 'Foreclosure'
				  group by d.[LOAN DATE]

		/* Payoffs */
		SELECT Payoffs = isnull(count(distinct l.[loan number]),0)
		,PayoffDate = l.[payment in full date]
		INTO #Payoffs
 		FROM #delinquency_snapshot c  
		INNER JOIN bdesime.[dbo].[loan] l (nolock) ON c.[loan number] = l.[loan number]
		 where convert(date,l.[payment in full date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@localEndDate)) - 0, 0) and convert(date,@localEnddate)
		 AND l.[payment in full date] IS NOT NULL
		 group by l.[payment in full date]

		  /* New Loans */
			SELECT [Loan Date] = CAST([NEW LOAN SETUP DATE] as date)  
			,NewLoans = isnull(count(distinct ol.[LOAN NUMBER]),0)
			INTO #NewLoans
	 		FROM #delinquency_snapshot c  
			INNER JOIN BDESIME.[dbo].[original_loan] ol (nolock) ON ol.[LOAN NUMBER] = c.[loan number]
			WHERE   CAST([NEW LOAN SETUP DATE] as date) Between  DATEADD(mm, DATEDIFF(mm, 0, @localenddate), 0) and @localenddate	
			-- and ol.delta_file_byte = 'A'
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

	IF object_id('tempdb.dbo.#buckets')				IS NOT NULL	DROP TABLE #buckets
	IF object_id('tempdb.dbo.#Status')				IS NOT NULL	DROP TABLE #Status
	IF object_id('tempdb.dbo.#REO')					IS NOT NULL	DROP TABLE #REO
	IF object_id('tempdb.dbo.#Active')				IS NOT NULL	DROP TABLE #Active
	IF object_id('tempdb.dbo.#Payoffs')				IS NOT NULL	DROP TABLE #Payoffs
	IF object_id('tempdb.dbo.#NewLoans')			IS NOT NULL	DROP TABLE #NewLoans
	IF object_id('tempdb.dbo.#FHApreConveyance')	IS NOT NULL DROP TABLE #FHApreConveyance
	IF object_id('tempdb.dbo.#Foreclosure')			IS NOT NULL	DROP TABLE #Foreclosure
	IF object_id('tempdb.dbo.#Bankruptcy')			IS NOT NULL	DROP TABLE #Bankruptcy
	IF object_id('tempdb.dbo.#ClientLoans')			IS NOT NULL	DROP TABLE #ClientLoans
	IF object_id('tempdb.dbo.#delinquency_snapshot') IS NOT NULL DROP TABLE #delinquency_snapshot
	-- exec [dbo].[sp_portfolio_summary_by_State] '11/14/2017','ssv801','AK, AL, AR, AZ, CA, CO, CT, DC, DE, FL, GA, HI, IA, ID, IL, IN, KS, KY, LA, MA, MD, ME, MI, MN, MO, MS, MT, NC, ND, NE, NH, NJ, NM, NV, NY, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VA, VT, WA, WI, WV, WY'

GO


