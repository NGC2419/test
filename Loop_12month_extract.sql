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

		  SELECT DISTINCT @loanNumber 
				,[FirstDayOfMonth]
				,[LastDayOfMonth] 
				,[Year]
				,[Month]
				,[YYYYMM]
		INTO #months		
		   FROM DateDimension (nolock)
		  WHERE convert(Date,[LastDayOfMonth]) BETWEEN EOMONTH(@localBegin12Months) and EOMonth(@localEnd12Months) -- 12-months
		ALTER TABLE #results ADD RowID int identity(1,1)

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


 CREATE TABLE #loan ([ln_no] varchar(30),[NextPaymentDueDate] date, [load_date] date, LastTranDate date, [MonthlyPmtDueAmount] numeric(18,2), [Year] int, [month] int, [YYYYMM] int, [DLQstatus] varchar(60), DLQType varchar(4), DLQamount numeric(13,2) ) 
			  SET @i  = 1
			WHILE @i <= 12
				BEGIN
				SET @loopDate = (Select LastDayOfMonth from #results where [RowID] = @i)
				INSERT INTO #loan
 				SELECT distinct l.[ln_no]	
						, [NextPaymentDueDate]			= convert(date,l.[ln_nxt_pmt_due_dt])
						, [load_date]				= convert(date,l.[load_date])
						, [LastTranDate]				= convert(date,l.[ln_last_tran_dt])
						, [MonthlyPmtDueAmount]			= convert(numeric(18,2),l.[ln_monthly_pmt_am]	)
						, [Year]					= datepart(year,@loopDate)
						, [month]					= datepart(month,@loopDate)
						, [YYYYMM]                  = convert(int,concat(convert(char(4), datepart(year,@loopDate)), convert(varchar(2),CASE WHEN datepart(month,@loopDate) > 9 THEN convert(varchar(2),datepart(month,@loopDate))	ELSE '0' + convert(char(1),datepart(month,@loopDate)) END)))
						,[DLQstatus]   = d.[proper_status]
						,DLQType = CASE WHEN 'Pre-30 Days Delinquent' THEN 'p30' 
							            WHEN 'Prepaid or Current' THEN 'cur'
								WHEN '30 Days Delinquent' THEN '30'
								WHEN '60 Days Delinquent' THEN '60'
								WHEN '90 Days Delinquent' THEN '90'
							     ELSE '120' END      ----WHEN '120+ Days Delinquent' THEN '120'
						,[DLQamount] = 0.00
				FROM bde_Data.dbo.ufnGetMax_loan(convert(date,@loopDate)) l
				JOIN bdesime.dbo.delinquency_snapshot d  on l.ln_no = d.[Loan Number]
				AND l.iv_id = d.[INVESTOR ID] AND l.iv_cat_cd = d.iv_cat_cd
				WHERE ln_no IN ('0000997379','0001020627','0010776706','0030645840','001511461','0011481785','0011451820','0014194021', '0014103378','0030089502','0030181259','0030392567','0015113681','0002139285') 
				AND convert(date,l.load_date) = convert(date,d.[loan date]
				-- AND convert(date,l.load_date) between @localBegin12Months  and @localEnd12Months 
				GROUP BY l.ln_no, l.[ln_nxt_pmt_due_dt], l.[ln_last_tran_dt], l.[ln_monthly_pmt_am],l.[load_date],d.[proper_status]
				SET @i = @i + 1
				END

	select * from #loan
use bde_data
go
--            delete from loan where ln_no IN ('0000997379','0001020627','0010776706','0030645840','001511461','0011481785,'0011451820','0014194021', '0014103378','0030089502','0030181259','0030392567','0015113681','0002139285') 
--	INSERT INTO loan ([ln_no],[NextPaymentDueDate], [load_date], LastTranDate, [MonthlyPmtDueAmount], [Year], [month], [YYYYMM], [DLQstatus], DLQType, DLQamount) 
--	select [ln_no],[NextPaymentDueDate], [load_date], LastTranDate, [MonthlyPmtDueAmount], [Year], [month], [YYYYMM], [DLQstatus], DLQType, DLQamount from #loan
