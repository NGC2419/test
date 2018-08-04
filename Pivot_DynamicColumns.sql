DECLARE @enddate as datetime = '12/6/2016', @Client_Code varchar(max) = 'all', @State varchar(200) = 'all'

	DECLARE @localEndDate as datetime = @enddate
	,@localState varchar(3) = @State
	,@localClientCode varchar(MAX)
	,@all char(3) = 'All'

	select @localClientCode = coalesce(@localClientCode+',','') + client from (select distinct client from investor_client) t
	select @localClientCode = CASE WHEN @Client_Code = @all THEN @localClientCode ELSE @Client_Code END

	select distinct l.ln_no, l.iv_id, l.iv_cat_cd, iv_nm = ic.investor
	INTO #ClientLoans
 	FROM dbo.ufnGetMax_loan(@localEndDate) l
	INNER JOIN investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 
	JOIN  dbo.property p on l.ln_no = p.[ln_no]
	WHERE p.[pr_alpha_state_cd] LIKE (CASE @localState WHEN 'All' THEN '%' ELSE @localState END)
	CREATE NONCLUSTERED INDEX [loanLn_No] ON #ClientLoans ([ln_no] ASC)
		
		-- retrieve full months only
		select distinct [loan date] into #EOMdates from bdesime.dbo.delinquency_snapshot where [is eom] = 1 and [loan date] NOT IN ('2016-07-30','2016-07-31')
		Delete from #EOMdates where convert(date,[loan date]) NOT IN (select top 12 [loan date] from #EOMdates order by [loan date] desc)
		
		 select d.[loan date] 
				,d.[Loan Number]
				,d.proper_status
				,d.[MTH STATUS NAME]
				,d.[FIRST PRINCIPAL BALANCE] 
				,[is eom]
				into #delinquency_snapshot
			-- from 12 months ago thru @localEndDate
				 FROM #ClientLoans c  INNER JOIN bdesime.dbo.delinquency_snapshot d ON c.[ln_no] = d.[LOAN NUMBER]
				where [is eom] = 1 and  d.[FIRST PRINCIPAL BALANCE] <> 0 
				and convert(date,d.[loan date]) IN (select [loan date] from #EOMdates)
							
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
	order by [loan date], d.[MTH STATUS NAME]

--select * from #EOMdates 
DECLARE @cols Varchar(max)
		, @query varchar(max)
SELECT @cols = COALESCE(@cols + ',[' , '') + convert(varchar(30),[loan date],101) + ']' FROM #EOMdates
SET @cols = '[' + @cols 

	/* Pivot into Loan Status columns */
	-- select * into #Status
	SET @query = 'SELECT [status], ' + @cols + ' INTO ##pivoted FROM 
					(
						SELECT [Loan Date] 
							, [COUNT] = loans
							, [status] 
						FROM #buckets
					) s
					PIVOT
					(
						Sum([count])
						FOR [Loan Date] IN (' +  @cols + ' )
					) pvt '
		execute(@query)
		select * from ##pivoted