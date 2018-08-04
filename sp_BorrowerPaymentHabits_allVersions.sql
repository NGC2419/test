/*  gets 12 months of test data from loan and delinquency tables  */

USE [BDE_Data]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
declare @endDate date='3/31/2017',@loanNumber varchar(30) = '0001020627'

	DECLARE @localloanNumber		varchar(40) = @loanNumber
			,@localEndDate			date = @endDate
			,@localBegin12Months	date
			,@localEnd12Months		date
			,@RowID					int = 0
			,@loopDate				date 
			,@i						int = 0
			,@j						int = 0
			,@median				int = 9
			-- @localClientCode varchar(max) = @ClientCode
			-- @localUserid varchar(max) = @Userid

	Set @localEnd12Months	= convert(date,dateadd(month,-1,@localEndDate) )
	Set @localBegin12Months = convert(date,dateadd(month, datediff(month, 0, convert(date,DATEADD(MONTH, -12,@localEndDate))) - 0,0))

			
	/*** Dates ***/ 

		  SELECT DISTINCT loanNumber  = @loanNumber 
				,[FirstDayOfMonth]
				,[LastDayOfMonth] 
				,[Year]
				,[Month]
				,[YYYYMM]
		INTO #months		
		   FROM DateDimension (nolock)
		  WHERE convert(Date,[LastDayOfMonth]) BETWEEN EOMONTH(@localBegin12Months) and EOMonth(@localEnd12Months) -- 12-months
		ALTER TABLE #months ADD RowID int identity(1,1)

	/*** Payments ***/ 

		-- processed payment transactions
		SELECT   [LOAN NUMBER]			= convert(varchar(30),[LOAN NUMBER])
				,[SID]					= convert(int,[SID])
				,[PMT DUE DATE]			= convert(date,[PMT DUE DATE])
				,[PMT TRANSACTION DATE] = convert(date,[PMT TRANSACTION DATE])
				,[PMT TOTAL AMOUNT]		= convert(numeric(18,2),isnull([PMT TOTAL AMOUNT],0))
	 			,[PMT FEE AMOUNT]		= convert(numeric(18,2), CASE WHEN  [PMT FEE CODE] = '1' THEN isnull([PMT FEE AMOUNT],0) ELSE 0.00 END)
				,[Year_xactDate]		= year([PMT TRANSACTION DATE])
				,[Month_xactDate]		= month([PMT TRANSACTION DATE])
				,[YYYYMM_xactDate]		= (convert(int,concat(convert(char(4), datepart(year,[PMT TRANSACTION DATE])), convert(varchar(2),CASE WHEN datepart(month,[PMT TRANSACTION DATE]) > 9 THEN convert(varchar(2),datepart(month,[PMT TRANSACTION DATE]))	ELSE '0' + convert(char(1),datepart(month,[PMT TRANSACTION DATE])) END))))
				,[BOM_xactDate]			= convert(date,DATEADD(MONTH, DATEDIFF(MONTH, 0,[PMT TRANSACTION DATE]), 0))
				,[EOM_xactDate]			= convert(date,Eomonth([PMT TRANSACTION DATE]))
				,[Year_DueDate]			= year([PMT DUE DATE])
				,[Month_DueDate]		= month([PMT DUE DATE])
				,[YYYYMM_DueDate]		= (convert(int,concat(convert(char(4), datepart(year,[PMT DUE DATE])), convert(varchar(2),CASE WHEN datepart(month,[PMT DUE DATE]) > 9 THEN convert(varchar(2),datepart(month,[PMT DUE DATE]))	ELSE '0' + convert(char(1),datepart(month,[PMT DUE DATE])) END))))
				,[BOM_DueDate]			= convert(date,DATEADD(MONTH, DATEDIFF(MONTH, 0,[PMT DUE DATE]), 0))
				,[EOM_DueDate]			= convert(date,Eomonth([PMT DUE DATE]))
		 INTO #allPayments
		 FROM [BDESime].[dbo].[payment_tran] (NOLOCK) pt
		WHERE convert(date,[PMT TRANSACTION DATE]) between @localBegin12Months and @localEnd12Months
		  AND [PMT TRANSACTION CODE]  in ('170','171','172','173','174','175') 
		  AND convert(int,[PMT TOTAL AMOUNT]) <> 0
		  AND [loan number] IN ('0000997379','0001020627','0010776706','0030645840','001511461','0011481785','0011451820','0014194021', '0014103378','0030089502','0030181259','0030392567','0015113681','0002139285') 


 			/*** Loans ***/ 
		   CREATE TABLE #loan ([ln_no] varchar(30),[NextPaymentDueDate] date, LastTranDate date, [MonthlyPmtDueAmount] numeric(13,2)
						,[LoanTotalPaymentDueAmount]  numeric(13,2), [MaxTotalPaymentDueAmount]  numeric(13,2), [Year] int, [month] int, [YYYYMM] int, [DLQstatus] varchar(40), ln_next_paymt_no int
						, co_delq_cd varchar(8),snapshot_mspStatus varchar(8), [SUSPENSE BALANCE] numeric(13,2) )
			  SET @i  = 1
			WHILE @i <= 25
				BEGIN
				SET @loopDate = (Select LastDayOfMonth from #months where [RowID] = @i)
				INSERT INTO #loan
				SELECT distinct l.[ln_no]	
						, [NextPaymentDueDate]		= convert(date,l.ln_nxt_pmt_due_dt)
						, [LastTranDate]			= convert(date,l.[ln_last_tran_dt])
						, [MonthlyPmtDueAmount]		= convert(numeric(13,2),l.[ln_monthly_pmt_am])
						, [LoanTotalPaymentDueAmount] = convert(numeric(13,2),dtl.co_dlq_pmt_ba)
						, [MaxTotalPaymentDueAmount] = convert(numeric(13,2),d.co_dlq_pmt_ba)
						, [Year]					= datepart(year,@loopDate)
						, [month]					= datepart(month,@loopDate)
						, [YYYYMM]                  = convert(int,concat(convert(char(4), datepart(year,@loopDate)), convert(varchar(2),CASE WHEN datepart(month,@loopDate) > 9 THEN convert(varchar(2),datepart(month,@loopDate))	ELSE '0' + convert(char(1),datepart(month,@loopDate)) END)))
						, [DLQstatus]				= 	CASE  WHEN d.co_delq_cd  IN ('1','2','3','4') THEN 'Delinquent' 
															  WHEN d.co_delq_cd  IN ('A','B','C','D','P') THEN 'Current' 
														ELSE NULL END
						, l.ln_next_paymt_no
						, co_delq_cd				= d.co_delq_cd 
						, snapshot_mspStatus		= ds.[msp dlq status]  
						, [SUSPENSE BALANCE]
				FROM bde_Data.dbo.ufnGetMax_loan(convert(date,@loopDate)) l
				left JOIN (SELECT tt.ln_no,load_date,co_delq_cd,co_dlq_pmt_ba = groupedtt.co_dlq_pmt_ba
						FROM  [dbo].[delinquency] tt (nolock) 
						INNER JOIN
							(   SELECT ln_no, MAX(load_date) AS MaxDateTime
								, co_dlq_pmt_ba = max(co_dlq_pmt_ba)  -- largest amount due anytime during month 
								FROM [dbo].[delinquency] (nolock) WHERE CONVERT(VARCHAR(10), load_date, 111) <= EOMONTH(@loopDate) 
								GROUP BY ln_no) groupedtt 
						ON tt.ln_no = groupedtt.ln_no 
							AND tt.load_date = groupedtt.MaxDateTime and tt.ln_no = @loanNumber
							AND tt.delta_file_byte IN ('A','C')
					group by tt.ln_no,load_date,co_delq_cd, groupedtt.co_dlq_pmt_ba
					 ) d on l.ln_no = d.ln_no
			  LEFT JOIN bdesime.dbo.delinquency_snapshot ds (nolock) on l.ln_no = ds.[loan number]  and convert(date,[loan date]) = eomonth(@loopdate)
			  -- 5/12 added EOM amount due
			  left JOIN dbo.ufn_GetMax_delinquency_prodVersion(convert(date,@loopDate)) dtl on l.ln_no = dtl.ln_no 
			--  left JOIN ufn_GetMax_delinquency_prodVersion (convert(date,@loopDate)) dtl on l.ln_no = dtl.ln_no 
				WHERE l.ln_no = @localloanNumber 
				--INNER JOIN bde_data.dbo.investor_client ic ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
					--AND ic.client IN  (select [BDESime].[dbo].[fnGetSimeUserClientCode](@localUserid)) 			
				GROUP BY l.ln_no, l.ln_nxt_pmt_due_dt, l.[ln_last_tran_dt], l.[ln_monthly_pmt_am],l.[ln_tot_pymt_due_am],l.ln_next_paymt_no,d.co_dlq_pmt_ba,d.co_delq_cd,ds.[msp dlq status],[SUSPENSE BALANCE],dtl.co_dlq_pmt_ba
				SET @i = @i + 1
				END

 select * from #months
	select * from #loan

  drop table #months, #allpayments, #loan
go
--  delete from #loan where ln_no IN ('0000997379','0001020627','0010776706','0030645840','001511461','0011481785,'0011451820','0014194021', '0014103378','0030089502','0030181259','0030392567','0015113681','0002139285') 
--	INSERT INTO #loan ([ln_no],[NextPaymentDueDate], [load_date], LastTranDate, [MonthlyPmtDueAmount], [Year], [month], [YYYYMM], [DLQstatus], DLQType, DLQamount) 
--	select [ln_no],[NextPaymentDueDate], [load_date], LastTranDate, [MonthlyPmtDueAmount], [Year], [month], [YYYYMM], [DLQstatus], DLQType, DLQamount from #loan
