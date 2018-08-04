use bde_data
go
-- =====================================================================================================
-- UPDATES UPB columns on the portfolio_summary_investor table
-- =====================================================================================================

-- select * from [Portfolio_Summary_Investor] order by loandate desc  
--  '2015-09-30', '2015-10-31','2015-11-30','2015-12-31','2016-01-31','2016-02-29','2016-03-31','2016-04-30','2016-05-31','2016-06-30','2016-07-31','2016-08-31','2016-09-30','2016-10-31','2016-11-30','2016-12-31','2017-01-31','2017-02-28','2017-03-31'

	DECLARE @localStartDate date = '2015-08-31'
		   ,@localEndDate date   = '2015-08-31'
      	   ,@localClientCode varchar(MAX) 
	select @localClientCode = coalesce(@localClientCode+',','') + client from (select distinct client from investor_client) t

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
			INTO #Delinquency_snapshot
			--FROM [BDESIME].[dbo].[delinquency_snapshot_history] d (nolock)   -- use for archived years like 2015
			FROM [BDESIME].[dbo].[delinquency_snapshot] d (nolock)
			INNER JOIN bde_data.dbo.investor_client ic ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
		 WHERE convert(date, d.[loan date]) BETWEEN @localStartDate AND @localEndDate
		 AND d.[MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent') 
		 AND d.[First Principal Balance] > 0 
		 	
		-- SD 3/27/2017 #806 Added UPB
			Select   [loan date] 
					,[Client]
					,[Investor]
					,[UPB] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
		    into #UPB
			FROM #delinquency_snapshot
			group by [loan date], Client, [Investor]

	/* Delinquency buckets */
	select  [Loan Date] 
		   ,[Client]
		   ,[Investor]
		   ,[Status] = [MTH STATUS NAME]
		   ,UPB_DLQ = sum([First Principal Balance])
		   into #buckets
		   FROM #delinquency_snapshot 
	where [MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent')
	group by [Loan Date], Client, [Investor], [MTH STATUS NAME]

	/* Pivot into Loan Status columns */
		SELECT  * into #StatusUPB
					FROM (
						SELECT 
							[status] 
							, [Client]
							, [Investor]
							, [Loan Date] 
							, [UPB_DLQ]
						FROM #buckets
					) as s
					PIVOT
					(
						Sum([UPB_DLQ])
						FOR [Status] IN ([Pre-30 Days Delinquent],[Prepaid or Current],[30 Days Delinquent],[60 Days Delinquent],[90 Days Delinquent],[120+ Days Delinquent])
					)AS pvt

		select DISTINCT [Client]
			  ,[Investor]
			  ,[Loan Date] 
			  ,[UPB_Prepaid or Current]		= isnull([Prepaid or Current],0.00)
			  ,[UPB_Pre-30 Days Delinquent] = isnull([Pre-30 Days Delinquent],0.00)
			  ,[UPB_30 Days Delinquent]		= isnull([30 Days Delinquent],0.00)
			  ,[UPB_60 Days Delinquent]		= isnull([60 Days Delinquent],0.00)
			  ,[UPB_90 Days Delinquent]		= isnull([90 Days Delinquent],0.00)
			  ,[UPB_120+ Days Delinquent]	= isnull([120+ Days Delinquent],0.00)
		INTO #Status
		from #StatusUPB 


	/* Real Estate Owned Loans  (REO)   */
				Select [loan date]
						, [Client]
						, [Investor]
  					   , [UPB_REO] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				 into #REO
				 FROM #delinquency_snapshot 
					 where [Proper_Status] like '%REO%'
				  group by [LOAN DATE], Client, [Investor]

	/* Active Loans */
			Select  d.[loan date]
				, [Client]
				, [Investor]
				,[UPB_Active] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				into #Active
				FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where d.[Proper_Status] not like '%REO%'
				  group by d.[LOAN DATE], [Client], [Investor]

	/* FHA Pre-Conveyance */
			Select  d.[loan date]
					, [Client]
					, [Investor]
					,[UPB_FHAPreConveyance] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				 into #FHApreConveyance
				 FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where  d.proper_status = 'FHA Pre-Conveyance'
				  group by d.[LOAN DATE], [Client], [Investor]

	/* Bankruptcy */
			Select  d.[loan date]
					, [Client]
					, [Investor]
					,[UPB_Bankruptcy] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				  into #Bankruptcy
				  FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where  d.proper_status = 'Bankruptcy'
				  group by d.[LOAN DATE], [Client], [Investor]
				  
	/* Foreclosure */
			Select  d.[loan date]
					, [Client]
					, [Investor]
					,[UPB_Foreclosure] = convert(numeric(19,2),isnull(sum([FIRST PRINCIPAL BALANCE]),0))
				into #Foreclosure
				FROM #delinquency_snapshot d 
				    JOIN [BDESIME].[dbo].[deliquency_sort] ds on d.proper_status = ds.proper_status
				  where d.proper_status = 'Foreclosure'
				  group by d.[LOAN DATE], [Client], [Investor]

	-- payoffs and new loans
	select distinct Client, Investor, ln_no= [loan number], iv_id, iv_cat_cd, iv_nm = investor, UPB = [First Principal Balance]
	INTO #ClientLoans
 	FROM #delinquency_snapshot 
	
	/* Payoffs */
	 SELECT ic.Client
	,ic.Investor
	,Payoffs = isnull(count(l.[LOAN NUMBER]),0)
	,LoanDate = @localEndDate
	,UPB_Payoffs = convert(numeric(19,2),isnull(sum(l.[FIRST PRINCIPAL BALANCE]),0))
	INTO #Payoffs
	FROM [BDESime].dbo.[loan]  l  
     INNER JOIN investor_client ic on ic.inv_id = l.[INVESTOR ID] and ic.inv_cat = l.[CATEGORY CODE]  
     INNER JOIN [dbo].[ufnGetMax_loan_POamt](@localEndDate)  l2 on  l2.ln_no = l.[LOAN NUMBER]       
     where convert(date,l.[PAYMENT IN FULL DATE]) BETWEEN convert(date,@localStartDate) and convert(date,@localEnddate)
	 group by ic.Client, ic.Investor

	/* New Loans */
	SELECT Client
			, Investor
			, LoanDate = @localEndDate
			, NewLoans = isnull(count(*),0)
			, UPB_NewLoans = convert(numeric(19,2),isnull(sum([UPB]),0))
			INTO #NewLoans
			FROM #ClientLoans c  INNER JOIN dbo.loan l (nolock) ON c.[ln_no] = l.[ln_no]
			LEFT JOIN BDESIME.[dbo].[original_loan] ol (nolock) ON ol.[LOAN NUMBER] = l.ln_no
	 WHERE convert(date,[NEW LOAN SETUP DATE]) Between @localStartDate and @localenddate	
		 and l.delta_file_byte = 'A'
		group by Client
			, Investor
			
				select DISTINCT s.[Client]		
					,s.[Investor]					 
					,[LoanDate]					= convert(date,s.[LOAN DATE])
					,[SortID]					= convert(int,convert(varchar(8),s.[LOAN DATE],112))
		            ,[UPB]						= convert(numeric(19,2),isnull(u.[UPB],0.00))
					,[UPB_NewLoans]				= convert(numeric(19,2),isnull(nl.[UPB_NewLoans],0.00))
					,[UPB_Payoffs]				= convert(numeric(19,2),isnull(p.[UPB_Payoffs],0.00))
					,[UPB_Active]				= convert(numeric(19,2),isnull(a.[UPB_Active],0.00))
					,[UPB_Prepaid or Current]	= convert(numeric(19,2),isnull(s.[UPB_Prepaid or Current],0.00))
					,[UPB_Current Month]		= convert(numeric(19,2),ISNULL(s.[UPB_Pre-30 Days Delinquent],0.00)) -- current month is same as pre-30
					,[UPB_30 Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_30 Days Delinquent],0.00))
					,[UPB_60 Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_60 Days Delinquent],0.00))
					,[UPB_90 Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_90 Days Delinquent],0.00))
					,[UPB_120+ Days Delinquent]	= convert(numeric(19,2),ISNULL(s.[UPB_120+ Days Delinquent],0) - isnull(r.[UPB_REO],0.00))
					,[UPB_REO]					= convert(numeric(19,2),isnull(r.[UPB_REO],0.00))
					,[UPB_Foreclosure]			= convert(numeric(19,2),ISNULL(f.UPB_Foreclosure,0.00))
					,[UPB_Bankruptcy]			= convert(numeric(19,2),ISNULL(b.UPB_bankruptcy,0.00))
					,[UPB_FHA_PreConveyance]	= convert(numeric(19,2),ISNULL(fha.[UPB_FHApreConveyance],0.00))
			INTO #UPB_Totals
			from #Status s
			left join #UPB u					on s.[LOAN DATE] = u.[LOAN DATE] and s.client = u.client AND s.Investor = u.Investor
			left join #REO r					on s.[LOAN DATE] = r.[LOAN DATE] AND s.Client = r.Client AND s.Investor = r.Investor
			left join #Active a					on s.[LOAN DATE] = a.[LOAN DATE] AND s.Client = a.Client AND s.Investor = a.Investor
			left join #NewLoans nl				on s.Client = nl.Client AND s.Investor = nl.Investor
			left join #Payoffs p				on s.Client = p.Client AND s.Investor = p.Investor
			left join #Bankruptcy b				on s.[LOAN DATE] = b.[LOAN DATE] AND s.Client = b.Client AND s.Investor = b.Investor
			left join #Foreclosure f			on s.[LOAN DATE] = f.[LOAN DATE] AND s.Client = f.Client AND s.Investor = f.Investor
			left join #FHApreConveyance fha		on s.[LOAN DATE] = fha.[LOAN DATE] AND s.Client = fha.Client AND s.Investor = fha.Investor
			order by s.[Client], s.[Investor],convert(date,s.[LOAN DATE])
	
				
   -- 		select Client,Investor, LoanDate,UPB,[UPB_NewLoans],[UPB_Payoffs],[UPB_Active],[UPB_Prepaid or Current],[UPB_Current Month],[UPB_30 Days Delinquent]
			--,[UPB_60 Days Delinquent],[UPB_90 Days Delinquent],[UPB_120+ Days Delinquent],[UPB_REO],[UPB_Foreclosure],[UPB_Bankruptcy],[UPB_FHA_PreConveyance] from #upb_totals
	
				UPDATE [dbo].[Portfolio_Summary_Investor]
				  SET [UPB_NewLoans]			= u.[UPB_NewLoans]
					,[UPB_Payoffs]				= u.[UPB_Payoffs]
					,[UPB_Active]				= u.[UPB_Active]
					,[UPB_Prepaid or Current]	= u.[UPB_Prepaid or Current]
					,[UPB_Current Month]		= u.[UPB_Current Month]
					,[UPB_30 Days Delinquent]	= u.[UPB_30 Days Delinquent]
					,[UPB_60 Days Delinquent]	= u.[UPB_60 Days Delinquent]
					,[UPB_90 Days Delinquent]	= u.[UPB_90 Days Delinquent]
					,[UPB_120+ Days Delinquent]	= u.[UPB_120+ Days Delinquent]
					,[UPB_REO]					= u.[UPB_REO]
					,[UPB_Foreclosure]			= u.UPB_Foreclosure
					,[UPB_Bankruptcy]			= u.UPB_bankruptcy
					,[UPB_FHA_PreConveyance]	= u.[UPB_FHA_PreConveyance]
				FROM [dbo].[Portfolio_Summary_Investor] p
			    JOIN #UPB_Totals u on p.[Client] = u.[Client]
				 AND p.Investor = u.Investor
				 AND convert(date,p.[LOANDATE]) = convert(date,u.[LOANDATE])
				 
				 select * from portfolio_summary_investor order by loandate asc
				
	/*
				--select * from portfolio_summary where convert(date,loandate) between '8/1/2015' and '12/31/2015' --= @localEndDate
				select Client,LoanDate,UPB,[UPB_NewLoans],[UPB_Payoffs],[UPB_Active],[UPB_Prepaid or Current],[UPB_Current Month],[UPB_30 Days Delinquent],[UPB_60 Days Delinquent],[UPB_90 Days Delinquent],[UPB_120+ Days Delinquent],[UPB_REO],[UPB_Foreclosure],[UPB_Bankruptcy],[UPB_FHA_PreConveyance]	
		       from portfolio_summary_investor  WHERE convert(date,LoanDate) Between '8/1/2015' and '8/31/2015' order by loanDate desc


			UPDATE [dbo].[Portfolio_Summary_Investor]
				 SET [UPB] = u.UPB
			   		,[UPB_NewLoans]		= u.[UPB_NewLoans]
					,[UPB_Payoffs]		= u.[UPB_Payoffs]
					,[UPB_Active]				= u.[UPB_Active]
					,[UPB_Prepaid or Current]	= u.[UPB_Prepaid or Current]
					,[UPB_Current Month]		= u.[UPB_Current Month]
					,[UPB_30 Days Delinquent]	= u.[UPB_30 Days Delinquent]
					,[UPB_60 Days Delinquent]	= u.[UPB_60 Days Delinquent]
					,[UPB_90 Days Delinquent]	= u.[UPB_90 Days Delinquent]
					,[UPB_120+ Days Delinquent]	= u.[UPB_120+ Days Delinquent]
					,[UPB_REO]					= u.[UPB_REO]
					,[UPB_Foreclosure]			= u.UPB_Foreclosure
					,[UPB_Bankruptcy]			= u.UPB_bankruptcy
					,[UPB_FHA_PreConveyance]	= u.[UPB_FHA_PreConveyance]
				FROM [dbo].[Portfolio_Summary_investor] p
				JOIN (
				SELECT client
				,investor
					,[UPB] 
			   		,[UPB_NewLoans]	
					,[UPB_Payoffs]
					,[UPB_Active]
					,[UPB_Prepaid or Current]	
					,[UPB_Current Month]		
					,[UPB_30 Days Delinquent]	
					,[UPB_60 Days Delinquent]	
					,[UPB_90 Days Delinquent]	
					,[UPB_120+ Days Delinquent]	
					,[UPB_REO]					
					,[UPB_Foreclosure]			
					,[UPB_Bankruptcy]			
					,[UPB_FHA_PreConveyance]	
				FROM [dbo].[Portfolio_Summary_investor] p where loandate = '8/30/2015'
				) u
				on p.[Client] = u.[Client] and p.investor = u.investor
				where p.[LoanDate] = '8/31/2015'
*/

	IF object_id('tempdb.dbo.#buckets')				IS NOT NULL	DROP TABLE #buckets
	IF object_id('tempdb.dbo.#Status')				IS NOT NULL	DROP TABLE #Status
	IF object_id('tempdb.dbo.#StatusUPB')			IS NOT NULL	DROP TABLE #StatusUPB
	IF object_id('tempdb.dbo.#UPB')					IS NOT NULL	DROP TABLE #UPB
	IF object_id('tempdb.dbo.#REO')					IS NOT NULL	DROP TABLE #REO
	IF object_id('tempdb.dbo.#Active')				IS NOT NULL	DROP TABLE #Active
	IF object_id('tempdb.dbo.#Payoffs')				IS NOT NULL	DROP TABLE #Payoffs
	IF object_id('tempdb.dbo.#NewLoans')			IS NOT NULL	DROP TABLE #NewLoans
	IF object_id('tempdb.dbo.#FHApreConveyance')	IS NOT NULL DROP TABLE #FHApreConveyance
	IF object_id('tempdb.dbo.#Foreclosure')			IS NOT NULL	DROP TABLE #Foreclosure
	IF object_id('tempdb.dbo.#Bankruptcy')			IS NOT NULL	DROP TABLE #Bankruptcy
	IF object_id('tempdb.dbo.#ClientLoans')			IS NOT NULL	DROP TABLE #ClientLoans
	IF object_id('tempdb.dbo.#delinquency_snapshot') IS NOT NULL DROP TABLE #delinquency_snapshot
	IF object_id('tempdb.dbo.#UPB_Totals')			IS NOT NULL	DROP TABLE #UPB_Totals

GO
