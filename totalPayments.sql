use bde_data 
go 
 declare @endDate date='12/31/2017',@loanNumber varchar(30) = '0011481785' --'0014194021'  -- '0001020627' -- '0030392567' --'0011481785' -- '0014103378'
 SET NOCOUNT ON;	
 			 
	DECLARE @localloanNumber		varchar(40) = @loanNumber
			,@localEndDate			date = @endDate
			,@localBegin12Months	date
			,@localEnd12Months		date
			,@RowID					int = 0
			,@loopDate				date 
			,@i						int = 0
			,@j						int = 0
			,@median				int = 9

	Set @localEnd12Months	= convert(date,dateadd(month,-1,EOMonth(@localEndDate)) )
	Set @localBegin12Months = convert(date,dateadd(month, datediff(month, 0, convert(date,DATEADD(MONTH, -13,@localEndDate))) - 0,0))

	CREATE TABLE #results(
		[Loan Number]						nvarchar(30),
		[Year]								int,
		[Month]								tinyint,
		[YYYYMM]							int,
		[FirstDayOfMonth]					date,
		[FirstDayOfNextMonth]				date,
		[LastDayOfMonth]					date,
		[NextPaymentDueDate]				date,
		[ln_next_paymt_no]					int,
		[YYYYMM_NextDueDate]				AS (convert(int,concat(convert(char(4), datepart(year,NextPaymentDueDate)), convert(varchar(2),CASE WHEN datepart(month,NextPaymentDueDate) > 9 THEN convert(varchar(2),datepart(month,NextPaymentDueDate))	ELSE '0' + convert(char(1),datepart(month,NextPaymentDueDate)) END)))),
		[LastTranDate]						date,
		[YYYYMM_xactDate]					AS (convert(int,concat(convert(char(4), datepart(year,[PMT TRANSACTION DATE])), convert(varchar(2),CASE WHEN datepart(month,[PMT TRANSACTION DATE]) > 9 THEN convert(varchar(2),datepart(month,[PMT TRANSACTION DATE]))	ELSE '0' + convert(char(1),datepart(month,[PMT TRANSACTION DATE])) END)))),
		[BOM_xactDate]						AS convert(date,DATEADD(MONTH, DATEDIFF(MONTH, 0,[PMT TRANSACTION DATE]), 0)),
		[EOM_xactDate]						AS convert(date,Eomonth([PMT TRANSACTION DATE])),
		[YYYYMM_DueDate]					AS (convert(int,concat(convert(char(4), datepart(year,[PMT DUE DATE])), convert(varchar(2),CASE WHEN datepart(month,[PMT DUE DATE]) > 9 THEN convert(varchar(2),datepart(month,[PMT DUE DATE]))	ELSE '0' + convert(char(1),datepart(month,[PMT DUE DATE])) END)))),
		[BOM_DueDate]						AS convert(date,DATEADD(MONTH, DATEDIFF(MONTH, 0,[PMT DUE DATE]), 0)),
		[EOM_DueDate]						AS convert(date,Eomonth([PMT DUE DATE])),
		[Pmt Due Date]						date,
		[Pmt Transaction Date]				date,
		[MinPmtTranDate]					date,
		[MaxPmtTranDate]					date,
		[GrandTotalAmountDLQ]				numeric(13, 2) DEFAULT 0.00,
		[Monthly Pmt Due Amount]			numeric(13, 2) DEFAULT 0.00,
		[Pmt Fee Amount]					numeric(13, 2) DEFAULT 0.00,
		[Total Amount Paid by Tran Month]	numeric(13, 2) DEFAULT 0.00,
		[Total Amount Paid by Due Month]	numeric(13, 2) DEFAULT 0.00,
		--[Payment Variance]					AS convert(numeric(13, 2), [LoanTotalPaymentDueAmount] - [Total Amount Paid by Tran Month] ),
		[Amount Due]						AS convert(numeric(13, 2), CASE WHEN  [LoanTotalPaymentDueAmount] = 0 THEN 0.00 ELSE [LoanTotalPaymentDueAmount] END),
		[MaxTotalPaymentDueAmount]			numeric(13,2)  DEFAULT 0.00,
		[LoanTotalPaymentDueAmount]			numeric(13,2)  DEFAULT 0.00,
		[LateChargeAmount]					numeric(13,2) DEFAULT 0.00,
		[LateChargeDate]					date,
		[LateChargeFlag]					AS convert(int,CASE WHEN LateChargeAmount > 0 THEN 1 ELSE 0 END),
		[LateFeeAmount]						numeric(13,2) DEFAULT 0.00,
		[LateFeeDate]						date,
		[LateFeeFlag]						int Default 0,
		[YYYYMM_lateFeeDate]				int,
		[DLQstatus]							varchar(40),
		[DLQstatusInd]						varchar(10),
		co_delq_cd							varchar(8),
		co_delq_cdNext						varchar(8),
		snapshot_mspStatus					varchar(8),
		[Suspense Balance]				    numeric(13,2),
		[PaymentReversals]				    numeric(13,2),
	    [PaymentFlag]						AS convert(int, CASE WHEN [Total Amount Paid by Tran Month] = 0  THEN 0 ELSE 1 END), -- 0 = no payment, 1 = payment
	    [PaymentDueFlag]					AS convert(int, CASE WHEN [LoanTotalPaymentDueAmount] = 0  THEN 0 ELSE 1 END), -- 0 = no payment, 1 = payment
        [ChartColor]						AS convert(varchar(20), CASE WHEN snapshot_mspStatus IN ('1','2','3','4') THEN 'Red' WHEN snapshot_mspStatus IN ('A','B','C','D','P') THEN 'LimeGreen' ELSE NULL END),
		[DQStatusCount]						AS convert(int,CASE WHEN snapshot_mspStatus = '1' then -1 WHEN snapshot_mspStatus = '2' then -2 WHEN snapshot_mspStatus = '3' then -3 WHEN snapshot_mspStatus = '4' then -4	ELSE 0 END),
		--LimeGreen
		[AmountPaidFull]				    numeric(13,2),
		-- LimeGreen diagonal
		[AmountPaidPartial]				   numeric(13,2),
		 -- Red diagonal Partial payment
		[AmountDue]						   numeric(13,2)
		 ) 
			
	/*** Dates ***/ 
		INSERT INTO #results ([Loan Number],[FirstDayOfMonth],[FirstDayOfNextMonth],[LastDayOfMonth],[Year],[Month],[YYYYMM])
		  SELECT DISTINCT @loanNumber 
				,[FirstDayOfMonth]
				,[FirstDayOfNextMonth]
				,[LastDayOfMonth] 
				,[Year]
				,[Month]
				,[YYYYMM]
		   FROM DateDimension (nolock)
		  WHERE convert(Date,[LastDayOfMonth]) BETWEEN EOMONTH(@localBegin12Months) and EOMonth(@localEnd12Months) -- 12-months
		ALTER TABLE #results ADD RowID int identity(1,1)
		
	/*** Payments ***/ 

		-- processed payment transactions
		SELECT DISTINCT [LOAN NUMBER]	= convert(varchar(30),[LOAN NUMBER])
				,[SID]					= convert(int,[SID])
				,[PMT DUE DATE]			= convert(date,[PMT DUE DATE])
				,[PMT TRANSACTION DATE] = convert(date,[PMT TRANSACTION DATE])
				,[PMT TRANSACTION CODE] = convert(int,[PMT TRANSACTION CODE])
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
		FROM [BDESime].[dbo].[payment_tran] pt (nolock)
		WHERE convert(date,[PMT TRANSACTION DATE]) between @localBegin12Months and @localEnd12Months
		  AND [PMT TRANSACTION CODE]  in ('170','171','172','173','174','175') 
		  AND convert(int,[PMT TOTAL AMOUNT]) <> 0
		  AND [loan number] = @localloannumber --->>>>>> try commenting this line to get all loans, maybe

       	
		-- Total payments when the Transaction Month equals the report Calendar Month
		UPDATE #results
		   SET [Pmt Transaction Date]					= p.[PMT TRANSACTION DATE]
			 , [Total Amount Paid by Tran Month]		= p.[PMT TOTAL AMOUNT] 
			 , [MinPmtTranDate]							= p.[MinPmtTranDate]
			 , [MaxPmtTranDate]							= p.[MaxPmtTranDate]
		FROM #results r
		JOIN (
			SELECT [LOAN NUMBER]	
				,[PMT TRANSACTION DATE]	= convert(date,max([PMT TRANSACTION DATE]))
				,[YYYYMM_xactDate]
				,[PMT TOTAL AMOUNT]		= convert(numeric(18,2),isnull(Sum([PMT TOTAL AMOUNT]),0))
				,[MinPmtTranDate]		= convert(date,min([PMT TRANSACTION DATE]))
				,[MaxPmtTranDate]		= convert(date,max([PMT TRANSACTION DATE]))
			FROM #allPayments 
			GROUP BY [LOAN NUMBER],[YYYYMM_xactDate]
			) p ON r.[Loan Number] = p.[Loan Number] 
			 WHERE r.YYYYMM = p.[YYYYMM_xactDate]

	 -- Total payments when the Payment Due Month equals the report Calendar Month
  		-- Add total payments to #results
		UPDATE #results
		   SET [Pmt Due Date]					= p.[Pmt Due Date]
			 , [Total Amount Paid by Due Month]	= p.[PMT TOTAL AMOUNT] 
		FROM #results r
		JOIN (
			SELECT [LOAN NUMBER]	
				,[SID]					= convert(int,max(sid))
				,[PMT DUE DATE]			= convert(date,[Pmt Due Date])
				,[YYYYMM_DueDate]
				,[PMT TOTAL AMOUNT]		= convert(numeric(18,2),isnull(Sum([PMT TOTAL AMOUNT]),0))
			FROM #allPayments 
			GROUP BY [LOAN NUMBER],[PMT DUE DATE],[YYYYMM_DueDate]
			) p ON r.[Loan Number] = p.[Loan Number] 
			and r.YYYYMM = p.YYYYMM_DueDate		


select [loan number]
, YYYYMM_DueDate
, DueDateCount = Case when YYYYMM_DueDate <> 0 THEN count(YYYYMM_DueDate) ELSE 0 END
--, YYYYMM_xactDate
--, xactDateCount = Case when YYYYMM_DueDate <> 0 THEN  count(YYYYMM_xactDate)  ELSE 0 END
from #results 

group by [Loan Number], YYYYMM_DueDate,YYYYMM_xactDate

drop table #results, #allPayments