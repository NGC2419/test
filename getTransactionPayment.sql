declare @startDate date='1/1/2017',@endDate date='1/31/2017',@loopDate date='1/31/2017' 
,@loanNumber varchar(30) = '0014103378'  ,@localloanNumber varchar(30) = '0014103378' 

---- get delinquency last day of current month / not rolled
--SELECT DISTINCT co_dlq_pmt_ba_max = max(co_dlq_pmt_ba) over ()
--			, passedDate =  eomonth(@endDate)
--FROM [dbo].[delinquency] 
--WHERE CONVERT(VARCHAR(10), load_date, 111)  between  @startDate  and   eomonth(@endDate)
--and  ln_no = @loanNumber


				SELECT distinct l.[ln_no]	
						, [NextPaymentDueDate]		= convert(date,l.ln_nxt_pmt_due_dt)
						, [LastTranDate]			= convert(date,l.[ln_last_tran_dt])
						, [MonthlyPmtDueAmount]		= convert(numeric(13,2),l.[ln_monthly_pmt_am])
						, [LoanTotalPaymentDueAmount] = convert(numeric(13,2),d.co_dlq_pmt_ba)
						, [Year]					= datepart(year,@loopDate)
						, [month]					= datepart(month,@loopDate)
						, [YYYYMM]                  = convert(int,concat(convert(char(4), datepart(year,@loopDate)), convert(varchar(2),CASE WHEN datepart(month,@loopDate) > 9 THEN convert(varchar(2),datepart(month,@loopDate))	ELSE '0' + convert(char(1),datepart(month,@loopDate)) END)))
						, [DLQstatus]				= 	CASE  WHEN co_delq_cd  IN ('1','2','3','4') THEN 'Delinquent' 
															  WHEN co_delq_cd  IN ('A','B','C','D','P') THEN 'Current' 
														ELSE NULL END
						, l.ln_next_paymt_no
						, co_delq_cd				= d.co_delq_cd 
						, snapshot_mspStatus		= ds.[msp dlq status]  
						, [SUSPENSE BALANCE]
				FROM bde_Data.dbo.ufnGetMax_loan(convert(date,@loopDate)) l
				left JOIN (SELECT tt.ln_no,load_date,co_delq_cd,co_dlq_pmt_ba = groupedtt.co_dlq_pmt_ba
						FROM  [dbo].[delinquency] tt (nolock) 
						INNER JOIN
							(   SELECT ln_no, MAX(load_date) AS MaxDateTime, co_dlq_pmt_ba = max(co_dlq_pmt_ba) 
								FROM [dbo].[delinquency] (nolock) WHERE CONVERT(VARCHAR(10), load_date, 111) <= EOMONTH(@loopDate) 
								GROUP BY ln_no) groupedtt 
						ON tt.ln_no = groupedtt.ln_no 
							AND tt.load_date = groupedtt.MaxDateTime and tt.ln_no = @loanNumber
							AND tt.delta_file_byte IN ('A','C')
					group by tt.ln_no,load_date,co_delq_cd, groupedtt.co_dlq_pmt_ba
					 ) d on l.ln_no = d.ln_no
			  LEFT JOIN bdesime.dbo.delinquency_snapshot ds (nolock) on l.ln_no = ds.[loan number]
			  and convert(date,[loan date]) = eomonth(@loopdate)
				WHERE l.ln_no = @localloanNumber 
				--	WHERE [Client] IN (select [BDESime].[dbo].[fnGetSimeUserClientCode](@localUserid))
				GROUP BY l.ln_no, l.ln_nxt_pmt_due_dt, l.[ln_last_tran_dt], l.[ln_monthly_pmt_am],l.[ln_tot_pymt_due_am],l.ln_next_paymt_no,d.co_dlq_pmt_ba,d.co_delq_cd,ds.[msp dlq status]  , [SUSPENSE BALANCE]
