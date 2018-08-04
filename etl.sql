USE [BDE_Data]
GO

--/****** Object:  StoredProcedure [dbo].[sp_ETL_import_for_portfolio_summary_table]    Script Date: 11/21/2017 4:20:18 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--CREATE PROCEDURE [dbo].[sp_ETL_import_for_portfolio_summary_table] 
--	  (@backfillDate date = NULL)
--AS
-- =====================================================================================================
-- Author:			SD
-- Create date:		12/14/2016
-- Description:		import ETL for table: bde_data.dbo.Portfolio_Summary
--
--					standard execution syntax: exec [dbo].[sp_ETL_import_for_portfolio_summary_table] 
--					backfill execution syntax: exec [dbo].[sp_ETL_import_for_portfolio_summary_table] '11/8/2017'
--
-- Modified:   
-- 			    11/15/2017 SDelaney #1086 Adjusted date logic
--				3/27/2017  SDelaney #806 Added Total UPB
--			    4/3/2017   SDelaney #828 Added UPB for all statuses
-- =====================================================================================================
-- select * from bde_data.dbo.Portfolio_Summary (nolock) order by LoanDate desc
 SET NOCOUNT ON;
 SET ANSI_WARNINGS OFF;
declare @backfillDate date = NULL

	DECLARE @localClientCode varchar(MAX) 
    DECLARE @localEndDate date = CASE WHEN @backfillDate IS NOT NULL THEN @backfillDate 
									  -- day prior to system date
									  ELSE DATEADD(d,-1,getdate())
								 END    

	-- if already loaded, remove it
		--IF EXISTS(select '' from dbo.Portfolio_Summary (nolock) Where convert(date,[LoanDate]) = convert(date,@localEnddate))
		--BEGIN
		--DELETE  from dbo.portfolio_summary  Where convert(date,[LoanDate]) = convert(date,@localEnddate)  
		--END

	    SELECT @localClientCode = coalesce(@localClientCode+',','') + client from (select distinct client from investor_client) t

		/* Delinquency Population */
		SELECT DISTINCT ic.Client
				,ic.Investor
				,iv_id = ic.inv_id
				,iv_cat_cd = ic.inv_cat
				,d.[Loan Number]
				,d.[Loan Date]
				,d.[Mth Status Name]
				,d.[Proper_Status] 
				,[Proper_Status2]  = CASE WHEN d.Proper_Status like 'REO%' THEN 'REO' ELSE d.Proper_Status END
				,d.[First Principal Balance]
				,ln_no = d.[loan number]
				,iv_nm = ic.investor
			INTO #Delinquency_snapshot
			FROM [BDESIME].[dbo].[delinquency_snapshot] d (nolock)
			INNER JOIN bde_data.dbo.investor_client ic (nolock) ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
		 WHERE d.[loan date] = @localEndDate
		 AND d.[MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent') 
		 AND d.[First Principal Balance] > 0 
		 	
		-- SD 3/27/2017 #806 Added UPB
			Select   [loan date] 
					,Client
					,[UPB] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
		    into #UPB
			FROM #delinquency_snapshot
			group by [loan date], Client

	/* Delinquency buckets */
	select  [Loan Date] 
		   ,[Client]
		   ,[Status] = [MTH STATUS NAME]
		   ,[Loans] = count([Loan Number]) 
		   ,UPB_DLQ = sum([First Principal Balance])
		   into #buckets
		   FROM #delinquency_snapshot 
	where [MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent')
	group by [Loan Date], Client, [MTH STATUS NAME]

	/* Pivot into Loan Status columns */
		SELECT  * into #StatusCounts
					FROM (
						SELECT 
							[status] 
							, [Client]
							, [Loan Date] 
							, [COUNT] = loans
						FROM #buckets
					) as s
					PIVOT
					(
						Sum([count])
						FOR [Status] IN ([Pre-30 Days Delinquent],[Prepaid or Current],[30 Days Delinquent],[60 Days Delinquent],[90 Days Delinquent],[120+ Days Delinquent])
					)AS pvt


		SELECT  * into #StatusUPB
					FROM (
						SELECT 
							[status] 
							, [Client]
							, [Loan Date] 
							, [UPB_DLQ]
						FROM #buckets
					) as s
					PIVOT
					(
						Sum([UPB_DLQ])
						FOR [Status] IN ([Pre-30 Days Delinquent],[Prepaid or Current],[30 Days Delinquent],[60 Days Delinquent],[90 Days Delinquent],[120+ Days Delinquent])
					)AS pvt

		select DISTINCT c.[Client]
			  ,c.[Loan Date] 
			  -- DLQ counts
			  ,[Prepaid or Current]		= isnull(c.[Prepaid or Current],0)
			  ,[Pre-30 Days Delinquent] = isnull(c.[Pre-30 Days Delinquent],0)
			  ,[30 Days Delinquent]		= isnull(c.[30 Days Delinquent],0)
			  ,[60 Days Delinquent]		= isnull(c.[60 Days Delinquent],0)
			  ,[90 Days Delinquent]		= isnull(c.[90 Days Delinquent],0)
			  ,[120+ Days Delinquent]	= isnull(c.[120+ Days Delinquent],0)
			  -- DLQ dollars
			  ,[UPB_Prepaid or Current]		= isnull(u.[Prepaid or Current],0.00)
			  ,[UPB_Pre-30 Days Delinquent] = isnull(u.[Pre-30 Days Delinquent],0.00)
			  ,[UPB_30 Days Delinquent]		= isnull(u.[30 Days Delinquent],0.00)
			  ,[UPB_60 Days Delinquent]		= isnull(u.[60 Days Delinquent],0.00)
			  ,[UPB_90 Days Delinquent]		= isnull(u.[90 Days Delinquent],0.00)
			  ,[UPB_120+ Days Delinquent]	= isnull(u.[120+ Days Delinquent],0.00)
		INTO #Status
		from #StatusUPB u
		join #StatusCounts c on u.Client = c.client and u.[loan date] = c.[loan date]

	/* Real Estate Owned Loans  (REO)   */
				Select [loan date]
						, [Client]
					    , REO = ISNULL(Count(*) ,0)				
  					   , [UPB_REO] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				 into #REO
				 FROM #delinquency_snapshot 
					 where [Proper_Status] like '%REO%'
				  group by [LOAN DATE], Client

	/* Active Loans */
			Select  d.[loan date]
				, [Client]
				,[Active] = isnull(Count(*),0)	
				,[UPB_Active] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				into #Active
				FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds  (nolock) on d.proper_status = ds.proper_status
				  where d.[Proper_Status] not like '%REO%'
				  group by d.[LOAN DATE], [Client]

	/* FHA Pre-Conveyance */
			Select  d.[loan date]
					, [Client]
					,[FHAPreConveyance] = isnull(Count(*),0)	
					,[UPB_FHAPreConveyance] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				 into #FHApreConveyance
				 FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds (nolock) on d.proper_status = ds.proper_status
				  where  d.proper_status = 'FHA Pre-Conveyance'
				  group by d.[LOAN DATE], [Client]

	/* Bankruptcy */
			Select  d.[loan date]
					, [Client]
					,[Bankruptcy] = isnull(Count(*),0)		
					,[UPB_Bankruptcy] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				  into #Bankruptcy
				  FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds (nolock) on d.proper_status = ds.proper_status
				  where  d.proper_status = 'Bankruptcy'
				  group by d.[LOAN DATE], [Client]
				  
	/* Foreclosure */
			Select  d.[loan date]
					, [Client]
					,[Foreclosure] = isnull(Count(*), 0)
					,[UPB_Foreclosure] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				into #Foreclosure
				FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds (nolock) on d.proper_status = ds.proper_status
				  where d.proper_status = 'Foreclosure'
				  group by d.[LOAN DATE], [Client]

	-- payoffs and new loans
	select distinct Client, ln_no= [loan number], iv_id, iv_cat_cd, iv_nm = investor, UPB = [First Principal Balance]
	INTO #ClientLoans
 	FROM #delinquency_snapshot 
	
	/* Payoffs */
	 SELECT ic.Client
	,LoanDate = @localEndDate
	,Payoffs = isnull(count(l.[LOAN NUMBER]),0)
	,UPB_Payoffs = convert(numeric(19,2),isnull(sum(l2.ln_1st_prin_ba),0))
	INTO #Payoffs
	FROM [BDESime].dbo.[loan]  l (nolock)
	INNER JOIN BDE_Data.dbo.investor_client ic (nolock) on ic.inv_id = l.[INVESTOR ID] and ic.inv_cat = l.[CATEGORY CODE]
	INNER JOIN BDE_Data.[dbo].[ufnGetMax_loan_POamt](@localenddate)  l2 on  l2.ln_no = l.[LOAN NUMBER] 				
     where convert(date,l.[PAYMENT IN FULL DATE]) = convert(date,@localEnddate)
	  and l.[LOAN NUMBER] = l2.ln_no
	group by ic.client  --,convert(date,l.[PAYMENT IN FULL DATE])
	
	/* New Loans */
	 SELECT ic.Client
	,LoanDate = @localEndDate
	,NewLoans = isnull(count(l.ln_no),0)
	,UPB_NewLoans = convert(numeric(19,2),isnull(sum(l.ln_1st_prin_ba),0))
	INTO #NewLoans
	FROM [BDE_data].dbo.[loan] l (nolock)
	INNER JOIN bde_data.dbo.investor_client ic (nolock) on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	LEFT JOIN BDESIME.[dbo].[original_loan] l2 (nolock) ON l2.[LOAN NUMBER] = l.ln_no
    WHERE convert(date,[NEW LOAN SETUP DATE]) = @localenddate	 -- Between  DATEADD(mm, DATEDIFF(mm, 0, @localenddate), 0) and @localenddate	
	 and l.delta_file_byte = 'A'
    and l.ln_no = l2.[LOAN NUMBER] 
	group by ic.client
			
	--/* SSRS Resultset */
	--INSERT INTO [dbo].[Portfolio_Summary]
 --          ([Client]
 --          ,[SortID]
 --          ,[LoanDate]
	--		-- SD 3/27/2017 #806 Added UPB
 --          ,[UPB]
 --          ,[NewLoans]
 --          ,[UPB_NewLoans]
 --          ,[Payoffs]
 --          ,[UPB_Payoffs]
 --          ,[Active]
 --          ,[UPB_Active]
 --          ,[Prepaid or Current]
 --          ,[UPB_Prepaid or Current]
 --          ,[Current Month]
 --          ,[UPB_Current Month]
 --          ,[30 Days Delinquent]
	--	   ,[UPB_30 Days Delinquent]
 --          ,[60 Days Delinquent]
	--	   ,[UPB_60 Days Delinquent]
 --          ,[90 Days Delinquent]
	--	   ,[UPB_90 Days Delinquent]
 --          ,[120+ Days Delinquent]
 --		   ,[UPB_120+ Days Delinquent]
 --          ,[REO]
 --		   ,[UPB_REO]
 --          ,[Foreclosure]
 --          ,[UPB_Foreclosure]
 --          ,[Bankruptcy]
 --		   ,[UPB_Bankruptcy]
 --          ,[FHA_PreConveyance]
 --          ,[UPB_FHA_PreConveyance]
	--	,[Is_EOM]
	--	   )
				select DISTINCT [Client]		= convert(varchar(20), s.Client) 
					,[SortID]					= convert(int,convert(varchar(8),s.[LOAN DATE],112))
					,[LoanDate]					= convert(date,s.[LOAN DATE])
					-- SD 3/27/2017 #806 Added Active UPB including REO's
		            ,[UPB]						= convert(numeric(19,2),isnull(u.[UPB],0.00))
					,[NewLoans]					= convert(int,isnull(nl.[NewLoans],0))
					,[UPB_NewLoans]				= convert(numeric(19,2),isnull(nl.[UPB_NewLoans],0.00))
					,[Payoffs]					= convert(int,isnull(p.[Payoffs],0))
					,[UPB_Payoffs]				= convert(numeric(19,2),isnull(p.[UPB_Payoffs],0.00))
					,[Active]					= convert(int,isnull(a.[Active],0))
					,[UPB_Active]				= convert(numeric(19,2),isnull(a.[UPB_Active],0.00))
					,[Prepaid or Current]		= convert(int,isnull(s.[Prepaid or Current],0.00))
					,[UPB_Prepaid or Current]	= convert(numeric(19,2),isnull(s.[UPB_Prepaid or Current],0.00))
					,[Current Month]			= convert(int,ISNULL(s.[Pre-30 Days Delinquent],0))  -- current month is same as pre-30
					,[UPB_Current Month]		= convert(numeric(19,2),ISNULL(s.[UPB_Pre-30 Days Delinquent],0.00)) -- current month is same as pre-30
					,[30 Days Delinquent]		= convert(int,ISNULL(s.[30 Days Delinquent],0))
					,[UPB_30 Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_30 Days Delinquent],0.00))
					,[60 Days Delinquent]		= convert(int,ISNULL(s.[60 Days Delinquent],0))
					,[UPB_60 Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_60 Days Delinquent],0.00))
					,[90 Days Delinquent]		= convert(int,ISNULL(s.[90 Days Delinquent],0))
					,[UPB_90 Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_90 Days Delinquent],0.00))
					,[120+ Days Delinquent]		= convert(int,ISNULL(s.[120+ Days Delinquent],0) - isnull(r.[REO],0))
					,[UPB_120+ Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_120+ Days Delinquent],0) - isnull(r.[UPB_REO],0.00))
					,[REO]						= convert(int,isnull(r.[REO],0))
					,[UPB_REO]					= convert(numeric(19,2),isnull(r.[UPB_REO],0.00))
					,[Foreclosure]				= convert(int,ISNULL(f.Foreclosure,0))
					,[UPB_Foreclosure]			= convert(numeric(19,2),ISNULL(f.UPB_Foreclosure,0.00))
					,[Bankruptcy]				= convert(int,ISNULL(b.bankruptcy,0))
					,[UPB_Bankruptcy]			= convert(numeric(19,2),ISNULL(b.UPB_bankruptcy,0.00))
					,[FHA_PreConveyance]		= convert(int,ISNULL(fha.[FHApreConveyance],0))
					,[UPB_FHA_PreConveyance]	= convert(numeric(19,2),ISNULL(fha.[UPB_FHApreConveyance],0.00))
					,[Is_EOM]					= CASE WHEN @localEndDate = EOMonth(@localEndDate) THEN 1 ELSE 0 END
			from #Status s
			left join #UPB u					on s.[LOAN DATE] = u.[LOAN DATE] and s.client = u.client
			left join #REO r					on s.[LOAN DATE] = r.[LOAN DATE] and s.client = r.client
			left join #Active a					on s.[LOAN DATE] = a.[LOAN DATE] and s.client = a.client
			left join #NewLoans nl				on s.[LOAN DATE] = nl.[LOANDATE] and s.client = nl.client
			left join #Payoffs p				on s.[LOAN DATE] = p.[LoanDate] and s.client = p.client
			left join #Bankruptcy b				on s.[LOAN DATE] = b.[LOAN DATE] and s.client = b.client
			left join #Foreclosure f			on s.[LOAN DATE] = f.[LOAN DATE] and s.client = f.client
			left join #FHApreConveyance fha		on s.[LOAN DATE] = fha.[LOAN DATE] and s.client = fha.client

--	IF object_id('tempdb.dbo.#buckets')				IS NOT NULL	DROP TABLE #buckets
--	IF object_id('tempdb.dbo.#StatusUPB')			IS NOT NULL	DROP TABLE #StatusUPB
--	IF object_id('tempdb.dbo.#StatusCounts')		IS NOT NULL	DROP TABLE #StatusCounts
--	IF object_id('tempdb.dbo.#Status')				IS NOT NULL	DROP TABLE #Status
--	IF object_id('tempdb.dbo.#UPB')					IS NOT NULL	DROP TABLE #UPB
--	IF object_id('tempdb.dbo.#REO')					IS NOT NULL	DROP TABLE #REO
--	IF object_id('tempdb.dbo.#Active')				IS NOT NULL	DROP TABLE #Active
--	IF object_id('tempdb.dbo.#Payoffs')				IS NOT NULL	DROP TABLE #Payoffs
--	IF object_id('tempdb.dbo.#NewLoans')			IS NOT NULL	DROP TABLE #NewLoans
--	IF object_id('tempdb.dbo.#FHApreConveyance')	IS NOT NULL DROP TABLE #FHApreConveyance
--	IF object_id('tempdb.dbo.#Foreclosure')			IS NOT NULL	DROP TABLE #Foreclosure
--	IF object_id('tempdb.dbo.#Bankruptcy')			IS NOT NULL	DROP TABLE #Bankruptcy
--	IF object_id('tempdb.dbo.#ClientLoans')			IS NOT NULL	DROP TABLE #ClientLoans
--	IF object_id('tempdb.dbo.#delinquency_snapshot') IS NOT NULL DROP TABLE #delinquency_snapshot

--GO
--select * from #Delinquency_snapshot where client = 'ssv801'
--select * from #Delinquency_snapshot where client = 'ssv801' and proper_status2 = 'bankruptcy'

---select * from portfolio_summary where LoanDate > '11/15/2017'