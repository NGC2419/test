USE BDE_Data
GO
DECLARE @enddate		date = '9/30/2016', @Client_Code varchar(MAX) = 'tms000'

	DECLARE  @localEnddate date = @enddate
	DECLARE  @BusinessDay date = @localEndDate	
			,@PriorDay date = CASE WHEN ( DATENAME(weekday,@localEndDate) = 'Monday' ) THEN CAST(dateadd(day,-3,@localEndDate) as date) 
								   WHEN ( DATENAME(weekday,@localEndDate) = 'Sunday' ) THEN CAST(dateadd(day,-2,@localEndDate) as date)
								   WHEN ( DATENAME(weekday,@localEndDate) IN ('Tuesday','Wednesday','Thursday','Friday','Saturday')) THEN CAST(dateadd(day,-1,@localEndDate) as date) END
			,@PriorMonthStart date = DATEADD(m,DATEDIFF(m,0, @localEndDate)-1,0)				
			,@PriorMonthEnd date = dateadd(month,-1,EOMonth(@localEndDate))						
			,@StartOfMonth date = DATEADD(month, DATEDIFF(month, 0, @localEndDate), 0)  
			,@localClientCode varchar(MAX) = @Client_Code

    select  l.ln_no
			, l.iv_id
			, l.iv_cat_cd
			, iv_nm = ic.investor
			, l.load_date
			, ln_nsf_ba
			, ln_suspense_ba 
			, ln_1st_prin_ba
			, ln_acr_lte_chrg_am
	 INTO #ClientLoans
     FROM BDE_Data.dbo.ufnGetMax_loan(@localEndDate) l
	 INNER JOIN BDE_Data.dbo.investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	 AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 

			Select  ln_1st_prin_ba			= sum(l.ln_1st_prin_ba)
	        , [MiscFees]					= sum(l.ln_acr_lte_chrg_am) + sum(l.ln_nsf_ba) -- + sum(col_oth_fee_due_am)
			, [AccruedLateCharges]			= sum(l.ln_acr_lte_chrg_am) 
			, NSF							= sum(l.ln_nsf_ba) 
			, [Suspense]					= sum(l.ln_suspense_ba) 
		
			, [Other Fees]					= sum(c.col_oth_fee_due_am)
		
			, [EscrowAdvBalance]			= sum(isnull(e.[es_adv_ba],0))
			, [EscrowBalance]				= sum(isnull(e.[es_ba],0))
			, [EscrowChargeAmt]			    = sum(isnull(e.es_bsc_svc_chg_am,0))
	FROM #ClientLoans l
	LEFT JOIN [bde_data].[dbo].ufngetMax_escrow(@localEndDate) e on l.ln_no = e.ln_no
	LEFT JOIN [bde_data].[dbo].ufngetMax_collections(@localEndDate) c on l.ln_no = c.ln_no

	-- get loan population   
	select l.ln_no
		, l.iv_id
		, l.iv_cat_cd
		, iv_nm = ic.investor
		, l.ln_monthly_pmt_am
		, load_date = convert(date,l.load_date)
		, Client= @localClientCode
		, l.ln_acr_lte_chrg_am 
		, l.ln_nsf_ba 
		, l.ln_suspense_ba
		, ln_1st_prin_ba
	INTO #LoanData
 	FROM BDE_Data.dbo.ufnGetMax_loan(@localEndDate) l
	INNER JOIN BDE_Data.dbo.investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 

	-- get @endDate loan population 
	select * INTO #LoanDay FROM #LoanData WHERE convert(date,load_date) = @localEndDate

	-- get prior day loan population 
	select * INTO #LoanPriorDay FROM #LoanData WHERE convert(date,load_date) = @PriorDay

	-- get MTD loan population
	select * INTO #LoanMTD FROM #LoanData WHERE convert(date,load_date) >= @StartOfMonth


		SELECT
		Num_Loans					= count(distinct l.ln_no) 
		,RecurringDraftsLn			= sum(ln_monthly_pmt_am) 
		,OneTimeDraftFee			= sum(otdf_fee_am)
		,OneTimeDraftFeeCount		= count(otdf_fee_am)
		,Payoffs					= sum(pf_payoff_am)
        ,pf_late_charge_am			= sum(pf_late_charge_am)
		,EscrowAdvance				= sum(es_adv_ba)
		,CorpAdv					= sum([adv_am])
		,ServicingFee				= sum(sv_sf_paid_amt)
		,OneTimeDrafts				= sum(otd_draft_fee_am)
		,OTDDraftFeeAmCount			= count(distinct otd_draft_fee_am)
		,otdTotalDraftAm			= sum(otd_total_draft_am)
		,otdTotalDraftAmCount		= count(distinct otd_total_draft_am)
		,AccruedLateFees			= sum(l.ln_acr_lte_chrg_am)
		,NSF_Fees					= sum(l.ln_nsf_ba)
		,Suspense					= sum(l.ln_suspense_ba)
		INTO #MTD
		from #LoanMTD l
		LEFT join [dbo].ufngetmax_payoff_stmt(@StartOfMonth) p						on l.ln_no = p.ln_no	 AND convert(date,p.load_date)	  = @StartOfMonth
		LEFT join [dbo].ufngetmax_escrow(@StartOfMonth) e							on l.ln_no = e.ln_no	 AND convert(date,e.load_date)	  = @StartOfMonth
		LEFT join [dbo].ufngetmax_servicing_fee(@StartOfMonth) sf					on l.ln_no = sf.ln_no	 AND convert(date,sf.load_date)	  = @StartOfMonth
		LEFT join [BDE_Data].[dbo].[corporate_adv_tran] ca (nolock)					on l.ln_no = ca.ln_no	 AND convert(date,ca.load_date)	  = @StartOfMonth
		LEFT JOIN (SELECT  SID,delta_file_byte, tt.ln_no ,otd_dt,otd_total_draft_am, otd_draft_fee_am, otd_curr_pymt_am, load_date
					FROM  [dbo].[one_time_draft]  tt
					INNER JOIN
					(SELECT ln_no, MAX(load_date) AS MaxDateTime
					FROM [dbo].[one_time_draft] where load_date <= (dateadd(day,datediff(day,-1,@enddate),0))  and  otd_dt <= @enddate
						GROUP BY ln_no) groupedtt 
						ON tt.ln_no = groupedtt.ln_no 
						AND tt.load_date = groupedtt.MaxDateTime and tt.delta_file_byte in ('A','C')
					) otd  on l.ln_no = otd.ln_no AND convert(date,otd.load_date)  = @StartOfMonth
		LEFT JOIN (SELECT client_no
						, tt.ln_no
						, otd_dt
						, otdf_seq_no
						, otdf_fee_am
						, otdf_fee_cd
						, otdf_eloc_fee_cd
				FROM [dbo].[one_time_draft_fee] tt
				INNER JOIN (
					 SELECT ln_no, MAX(load_date) AS MaxDateTime
					 FROM [dbo].[one_time_draft_fee]
					 WHERE load_date <= (DATEADD(DAY, DATEDIFF(DAY, -1, @enddate), 0))
					 GROUP BY ln_no) groupedtt ON tt.ln_no = groupedtt.ln_no
				 AND tt.load_date = groupedtt.MaxDateTime 
				 AND tt.delta_file_byte IN ('A','C')
					) otdf			on l.ln_no = otdf.ln_no AND convert(date,otdf.otd_dt)	 = @StartOfMonth
	
	;WITH FeeDetailMTD AS (
		SELECT ServicingFee_am		= pt.pmt_serv_fee_am
		,RecurringDrafts			= pt.pmt_sched_due_am
		,pt.pmt_fee_cd fee_code
		,code_description = case  when pt.pmt_fee_cd in ('0','3','4','F') then 'MiscFees'  
		--	 --when pt.pmt_fee_cd = '0' then 'MiscFees'
			   when pt.pmt_fee_cd = '1' then 'LateCharges'
			   when pt.pmt_fee_cd = '2' then 'NSFFees'
			 --when pt.pmt_fee_cd = '3' then 'Loan Assumption Fee'
			 --when pt.pmt_fee_cd = '4' then 'Recording Fee'
			   when pt.pmt_fee_cd = '6' then 'Payoff Statement Fee'
			   when pt.pmt_fee_cd = '7' then 'Balloon Title Endorsment Fee'
			   when pt.pmt_fee_cd = '8' then 'Courier Expenses'
			 --when pt.pmt_fee_cd = 'F' then 'Fax Fee'
			   when pt.pmt_fee_cd = 'K' then 'OTDFees'
			   when pt.pmt_fee_cd = 'R' then 'RecurringDraftFees'
			   when pt.pmt_fee_cd = '*' then 'SuspensePayments'
			   ELSE NULL
			   end 
		,Amount						= pt.pmt_fee_am
		from [dbo].ufnGetMax_payment_tran(@StartOfMonth) pt	
		where isnull(pt.pmt_fee_cd, '') <> ''
		--and pt.pmt_trans_cd not in (147,148)
		and pt.pmt_trans_cd in (170,171,172,173,174)
		--and convert(date,pt.load_date)	  = @StartOfMonth
		 and cast(pmt_trans_dt as date) = @StartOfMonth
		-- and cast(pf_as_of_dt as date) = @localenddate
		 --GROUP BY pt.pmt_fee_cd 
		 )

		 SELECT code_description 
		,Amount						= sum(Amount)
		,ServicingFee_am			= sum(ServicingFee_am)
		,RecurringDrafts			= sum(RecurringDrafts)
		,sumTotal					= sum(ServicingFee_am) + sum(Amount)
		INTO #FeeTotalsMTD
		from FeeDetailMTD	
		group by code_description

select * from #MTD
select * from #FeeTotalsMTD

-- drop table #clientloans, #mtd, #loandata,#LoanPriorDay,#LoanDay, #LoanMTD,#FeeTotalsMTD
