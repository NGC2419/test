USE [BDESime]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ========================================================================================
-- Author:		Susan Delaney
-- Create date: 8/11/2017
-- Description: reporting snapshot tables comparison 
-- ========================================================================================
DECLARE @clientCode varchar(max)='tms000,evb001', @endDate date = '7/31/2017', @includePostSale int=1

DECLARE @localClientCode      varchar(max) = @ClientCode
	  , @localincludePostSale int		   = @includePostSale
      , @localEndDate         date         = @endDate 
      , @server               varchar(20)  = convert(varchar(200),(SELECT SERVERPROPERTY('ServerName')))
--	  , @localStartDate	date		  = DateAdd(day,1,eomonth(dateadd(month, -1,@endDate)))

		SELECT d.[LOAN NUMBER]
			  ,[State] = p.[Property Alpha State Code]
			  ,p.[COUNTY CODE]
			  ,[FIRST PRINCIPAL BALANCE]
			  ,[LO TYPE] =		   CASE WHEN [LO TYPE] = '1'				THEN 'FHA Residential'
								        WHEN [LO TYPE] = '2'				THEN 'VA Residential'
								        WHEN [LO TYPE] IN ('3','6')			THEN 'Conventional Res Without PMI'
								        WHEN [LO TYPE] = '9'				THEN 'Rural Housing Service (RHS)'
								        ELSE '' 
								   END  
			   ,[SOURCE CHANNEL] = CASE WHEN [SOURCE CHANNEL] IN ('T','C')  THEN 'Correspondent'
										WHEN [SOURCE CHANNEL] = 'R'			THEN 'Retail'
										WHEN [SOURCE CHANNEL] = 'W'			THEN 'Wholesale'   
										ELSE '' 
									END
			   ,[MSP DLQ STATUS]
			   ,[Proper_Status]  = CASE WHEN d.Proper_Status like '%REO%'	THEN 'REO' ELSE (SELECT bde_data.dbo.ProperCase(d.Proper_Status)) END
			   ,[Status] =		   d.[MTH Status Name]
			   ,ActiveLoan = CASE WHEN d.Proper_Status like '%REO%' THEN 0 ELSE 1 END
			   ,NewLoanSetupDate = convert(date,o.ln_new_ln_setup_dt)
		  INTO #delinquency_snapshot
		  FROM bdesime.dbo.delinquency_snapshot d (nolock) 
    INNER JOIN bde_data.dbo.investor_client ic (nolock)				 ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
  		   AND ic.client IN (SELECT b.item FROM BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b)  
	 LEFT JOIN bde_data.dbo.ufnGetMax_credit_score(@localEndDate)  c ON d.[loan number] = c.[ln_no]
	 LEFT JOIN bde_data.dbo.ufngetmax_original_loan(@localEndDate) o ON d.[loan number] = o.[ln_no]
	 LEFT JOIN bdesime.dbo.property p (nolock)						 ON d.[loan number] = p.[loan number]
  	     WHERE convert(date,[loan date]) = @localEndDate
		   AND [FIRST PRINCIPAL BALANCE] > 0 
		   AND [proper_status] LIKE CASE WHEN @includePostSale = 0 THEN '[^reo]%' ELSE '%' END
				
		-- Pivot loans
		SELECT  [State]
				--,[FICO]
				,[Pre-30 Days Delinquent] = isnull([Pre-30 Days Delinquent],0)
				,[Prepaid or Current]	  = isnull([PrePaid or Current],0)
				,[30 Days Delinquent]	  = isnull([30 Days Delinquent],0)
				,[60 Days Delinquent]	  = isnull([60 Days Delinquent],0)
				,[90 Days Delinquent]	  = isnull([90 Days Delinquent],0)
				,[120+ Days Delinquent]	  = isnull([120+ Days Delinquent],0)
				    INTO #dlq	  
					FROM (
						SELECT 
							[status] 
							, [State] 
							--, [Fico] 
							, [LoanCount] = [Loan Number]
						FROM #delinquency_snapshot
					) as s
					PIVOT
					(
						Count([LoanCount])
					 FOR [Status] IN ([Pre-30 Days Delinquent],[Prepaid or Current],[30 Days Delinquent],[60 Days Delinquent],[90 Days Delinquent],[120+ Days Delinquent])
					)AS pvt

 		 SELECT  [Date] = @localEnddate
--				,l.[State]
				,UPB = sum(ds.[UPB])
				,[Loan Count] = sum(isnull([Pre-30 Days Delinquent],0) + isnull([PrePaid or Current],0) + isnull([30 Days Delinquent],0) + isnull([60 Days Delinquent],0) + isnull([90 Days Delinquent],0) + isnull([120+ Days Delinquent],0) )
				,[Prepaid or Current]	   = sum([Prepaid or Current])
				,[Pre-30 Days Delinquent]  = sum([Pre-30 Days Delinquent]) 
				,[30 Days Delinquent]	   = sum([30 Days Delinquent])	  
				,[60 Days Delinquent]	   = sum([60 Days Delinquent])
				,[90 Days Delinquent]	   = sum([90 Days Delinquent])
				,[120+ Days Delinquent]	   = sum([120+ Days Delinquent])
				,[Foreclosure]			   = sum(isnull(f.foreclosure,0))
				,[Bankruptcy]			   = sum(isnull(b.[Bankruptcy],0))
				,[FHAPreConveyance]		   = sum(isnull(fha.[FHAPreConveyance],0))
				,[PostSalePreConveyance]   = sum(isnull(psale.[PostSalePreConveyance] ,0))
		   INTO #DLQtotals
		   FROM #dlq l
		   LEFT JOIN (
						Select distinct [UPB] = isnull(Sum([FIRST PRINCIPAL BALANCE]), 0)
							, [STATE]
						 FROM #delinquency_snapshot
						  group by [STATE]
				  ) ds on l.[state] = ds.[STATE]
		   	/* Foreclosure */
		   LEFT JOIN (
						Select distinct [Foreclosure] = isnull(Count(*), 0)
							, [STATE]
						 FROM #delinquency_snapshot
						 where proper_status = 'Foreclosure'
						  group by [STATE]
				  ) f on l.[state] = f.[STATE]
			/* FHA Pre-Conveyance */
		   LEFT JOIN (
						Select distinct [FHAPreConveyance] = isnull(Count(*), 0)
							, [STATE]
						 FROM #delinquency_snapshot
						 where proper_status = 'FHA Pre-Conveyance'
						  group by [STATE]
				  ) fha on l.[state] = fha.[STATE]
			/* Bankruptcy */
			LEFT JOIN (
						Select distinct [Bankruptcy] = isnull(Count(*), 0)
							, [STATE]
						 FROM #delinquency_snapshot
						 where proper_status = 'Bankruptcy'
						  group by [STATE]
				  ) b on l.[state] = b.[STATE]
			/* Post Sale/PreConveyance   */
			LEFT JOIN (
						Select distinct [PostSalePreConveyance] = isnull(Count(*), 0)
							, [STATE]
						 FROM #delinquency_snapshot
						 where proper_status like '%REO%'
						  group by [STATE]
				  ) psale on l.[state] = psale.[STATE]
				  
			select * from (
					select [Server]			 = @server 
					, [Database]			 = 'BDE_Data'
					, [table]				 = 'dbo.portfolio_summary'
					, [LoanDate]			 = max(convert(date,[loandate]))
					, [UPB_AllLoans]		 = sum(UPB)
					, [AllLoans]			 = sum(active) + sum(reo) 
					--, [UPB_Active]			 = sum([UPB_Active])
					--, [ActiveLoans]			 = sum(active)
					, [Prepaid or Current]	 = sum([Prepaid or Current])
					, [Current Month]		 = sum([Current Month])
					, [30 Days Delinquent]	 = sum([30 Days Delinquent])
					, [60 Days Delinquent]	 = sum([60 Days Delinquent])
					, [90 Days Delinquent]	 = sum([90 Days Delinquent])
					, [120+ Days Delinquent] = sum([120+ Days Delinquent])
					, Foreclosure			 = sum(Foreclosure)
					, Bankruptcy			 = sum(Bankruptcy)
					, FHA_PreConveyance		 = sum(FHA_PreConveyance)
					, [PostSalePreConveyance] = sum(REO)
					from bde_data.dbo.portfolio_summary (nolock) 
					where convert(date,[loandate]) = @localEndDate
		UNION
					select [Server]			 = @server 
					, [Database]			 = 'BDE_Data'
					, [table]				 = 'dbo.portfolio_summary_investor'
					, [LoanDate]			 = max(convert(date,[loandate]))
					, [UPB_AllLoans]		 = sum(UPB)
					, [AllLoans]			 = sum(active) + sum(reo) 
					--, [UPB_Active]			 = sum([UPB_Active])
					--, [ActiveLoans]			 = sum(active)
					, [Prepaid or Current]	 = sum([Prepaid or Current])
					, [Current Month]		 = sum([Current Month])
					, [30 Days Delinquent]	 = sum([30 Days Delinquent])
					, [60 Days Delinquent]	 = sum([60 Days Delinquent])
					, [90 Days Delinquent]	 = sum([90 Days Delinquent])
					, [120+ Days Delinquent] = sum([120+ Days Delinquent])
					, Foreclosure			 = sum(Foreclosure)
					, Bankruptcy			 = sum(Bankruptcy)
					, FHA_PreConveyance		 = sum(FHA_PreConveyance)
					, [PostSalePreConveyance] = sum(REO)
					from bde_data.dbo.portfolio_summary_investor (nolock) 
					where convert(date,[loandate]) = @localEndDate 
		UNION
					select [Server]			 = @server 
					, [Database]			 = 'BDESime'
					, [table]				 = 'dbo.portfolio_summary_type'
					, [LoanDate]			 = max(convert(date,[loandate]))
					, [UPB_AllLoans]		 = sum(UPB)
					, [AllLoans]			 = sum(active) + sum(reo) 
					--, [UPB_Active]			 = sum([UPB_Active])
					--, [ActiveLoans]			 = sum(active)
					, [Prepaid or Current]	 = sum([Prepaid or Current])
					, [Current Month]		 = sum([Current Month])
					, [30 Days Delinquent]	 = sum([30 Days Delinquent])
					, [60 Days Delinquent]	 = sum([60 Days Delinquent])
					, [90 Days Delinquent]	 = sum([90 Days Delinquent])
					, [120+ Days Delinquent] = sum([120+ Days Delinquent])
					, Foreclosure			 = sum(Foreclosure)
					, Bankruptcy			 = sum(Bankruptcy)
					, FHA_PreConveyance		 = sum(FHA_PreConveyance)
					, [PostSalePreConveyance] = sum(REO)
					from bdesime.dbo.portfolio_summary_type (nolock) 
					where convert(date,[loandate]) = @localEndDate
		UNION
					select [Server]			 = @server 
					, [Database]			 = 'BDESime'
					, [table]				 = 'dbo.delinquency_snapshot'
					, [LoanDate]			 = @localEndDate
					, [UPB_AllLoans]		 = sum([UPB])
					, [AllLoans]			 = sum([loan count])
					--, [UPB_Active]			 = sum([first principal balance]) - (select sum([first principal balance]) from #DLQ WHERE proper_status = 'REO')
					--, [ActiveLoans]			 = sum([loans]) - - (select count([first principal balance]) from #DLQ WHERE proper_status = 'REO')
					, [Prepaid or Current]	 = sum([Prepaid or Current])
					, [Current Month]		 = sum([Pre-30 Days Delinquent])
					, [30 Days Delinquent]	 = sum([30 Days Delinquent])
					, [60 Days Delinquent]	 = sum([60 Days Delinquent])
					, [90 Days Delinquent]	 = sum([90 Days Delinquent])
					, [120+ Days Delinquent] = sum([120+ Days Delinquent])
					, Foreclosure			 = sum([Foreclosure])
					, Bankruptcy			 = sum([Bankruptcy])
					, FHA_PreConveyance		 = sum([FHAPreConveyance])
					, [PostSalePreConveyance] = sum([PostSalePreConveyance])
			from #DLQtotals
			) s
		order by convert(date,loandate),[table] 
		
		IF object_id('tempdb.dbo.#delinquency_snapshot') IS NOT NULL DROP TABLE #delinquency_snapshot
		IF object_id('tempdb.dbo.#dlq')				     IS NOT NULL DROP TABLE #dlq
		IF object_id('tempdb.dbo.#DLQtotals')			 IS NOT NULL DROP TABLE #DLQtotals
GO
