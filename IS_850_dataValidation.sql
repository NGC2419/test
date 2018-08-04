---
-- ================================================================================================
-- Author:			Susan Delaney
-- Create date:		4/28/2017
-- Description:		renders raw data from database tables for data validation for IS ticket (#850)
-- ================================================================================================
declare @UserID varchar(200) = 'glen.banta@themoneysource.com', @startDate date='5/1/2017',@endDate date='5/31/2017', @oneDay date = '1/31/2017', @loanNumber varchar(30) = '0014103378' -- '0014103378' -- '0011451820' -- '0011481785'  --'0014194021'  -- '0001020627' -- '0030392567' --'0011481785' -- '0014103378'  
exec sp_BorrowerPaymentHabits12Month @userid, @endDate, @loanNumber

-- get loan
SELECT distinct [table] = 'loan', ln_no	
    			--,[Calendar YYYYMM]		= (convert(int,concat(convert(char(4), datepart(year,getdate())), convert(varchar(2),CASE WHEN datepart(month,getdate()) > 9 THEN convert(varchar(2),datepart(month,getdate()))	ELSE '0' + convert(char(1),datepart(month,getdate())) END))))
						, [NextPaymentDueDate]		= convert(date,l.ln_nxt_pmt_due_dt)
						, [LastTranDate]			= convert(date,l.[ln_last_tran_dt])
						, [MonthlyPmtDueAmount]		= convert(numeric(13,2),l.[ln_monthly_pmt_am])
						, l.ln_next_paymt_no
				FROM bde_Data.dbo.ufnGetMax_loan(convert(date,@endDate)) l
				where  ln_no = @loanNumber 

select [table] = 'delinquency_snapshot',[loan number], [loan date], [msp dlq status] , [SUSPENSE BALANCE] , [MTH STATUS NAME]  
from BDESime.dbo.delinquency_snapshot 
where convert(date,[loan date]) in ( eomonth(@endDate), @oneday)
--where [loan date] in ('4/30/2016','5/31/2016','6/30/2016','7/31/2016','8/31/2016','9/30/2016','10/31/2016','11/30/2016','12/31/2016','1/31/2017','2/28/2017','3/31/2017','4/30/2017','5/31/2017')
--where [loan date] in ('4/1/2016','4/30/2016','5/1/2016','5/31/2016','6/1/2016','6/30/2016','7/1/2016','7/31/2016','8/1/2016','8/31/2016','9/1/2016','9/30/2016','10/1/2016','10/31/2016','11/1/2016','11/30/2016','12/1/2016','12/31/2016','1/1/2017','1/31/2017','2/1/2017','2/28/2017','3/1/2017','3/31/2017','4/1/2017','4/30/2017','5/1/2017')
and  [loan number] = @loanNumber
order by [loan date] desc

		--BDE_Data
select [table] = 'delinquency_detail'
			, ln_no
			, co_delq_cd
			, co_dlq_pmt_ba 
			, load_date 
from [delinquency]
where [ln_no] = @loanNumber
and [Load_Date] between  @startDate  and   eomonth(@endDate)
	
-- get payment_tran 
SELECT DISTINCT [table] = 'payment_tran', [LOAN NUMBER]	= convert(varchar(30),[LOAN NUMBER])
    			--,[Calendar YYYYMM]		= (convert(int,concat(convert(char(4), datepart(year,getdate())), convert(varchar(2),CASE WHEN datepart(month,getdate()) > 9 THEN convert(varchar(2),datepart(month,getdate()))	ELSE '0' + convert(char(1),datepart(month,getdate())) END))))
				,[PMT DUE DATE]			= convert(date,[PMT DUE DATE])
				,[PMT TRANSACTION DATE] = convert(date,[PMT TRANSACTION DATE])
				,[PMT TRANSACTION CODE] = convert(int,[PMT TRANSACTION CODE])
				,[PMT TOTAL AMOUNT]		= convert(numeric(18,2),isnull([PMT TOTAL AMOUNT],0))
FROM [BDESime].[dbo].[payment_tran] pt (nolock)
		WHERE convert(date,[PMT TRANSACTION DATE]) between @startDate  and  EOMONTH(@endDate) 
		  AND [PMT TRANSACTION CODE]  in ('170','171','172','173','174','175') 
		  AND convert(int,[PMT TOTAL AMOUNT]) <> 0
		  AND [loan number] = @loanNumber
		--   WHERE load_date between '4/1/2017'  and  EOMONTH('4/30/2017') 

---- get delinquency last day of current month / not rolled
--SELECT [table] = 'delinquency not rolled'
-- 			--,[Calendar YYYYMM]		= (convert(int,concat(convert(char(4), datepart(year,getdate())), convert(varchar(2),CASE WHEN datepart(month,getdate()) > 9 THEN convert(varchar(2),datepart(month,getdate()))	ELSE '0' + convert(char(1),datepart(month,getdate())) END))))
--			, ln_no
--			, co_delq_cd
--			, co_dlq_pmt_ba = co_dlq_pmt_ba
--			, co_dlq_pmt_ba_max = max(co_dlq_pmt_ba) over ()
--			, load_date 
--			, passedDate =  eomonth(@endDate)
--FROM [dbo].[delinquency] 
--WHERE CONVERT(VARCHAR(10), load_date, 111)  between  @startDate  and   eomonth(@endDate)
--and  ln_no = @loanNumber
--group by  ln_no			, co_delq_cd, load_date , co_dlq_pmt_ba
--order by load_date desc

-- get delinquency rolled to upcoming month

SELECT [table] = 'delinquency rolled'
 			--,[Calendar YYYYMM]		= (convert(int,concat(convert(char(4), datepart(year,getdate())), convert(varchar(2),CASE WHEN datepart(month,getdate()) > 9 THEN convert(varchar(2),datepart(month,getdate()))	ELSE '0' + convert(char(1),datepart(month,getdate())) END))))
			, ln_no
			, co_delq_cd
			--, co_dlq_pmt_ba = co_dlq_pmt_ba
			, co_dlq_pmt_ba_max = max(co_dlq_pmt_ba) 
			, load_date = min(load_date)
FROM [dbo].[delinquency] 
WHERE CONVERT(VARCHAR(10), load_date, 111)  between  @startDate  and   (DATEADD(DAY,DATEDIFF(DAY,-1,@endDate),0))
and  ln_no = @loanNumber
group by  ln_no, co_delq_cd--, co_dlq_pmt_ba
order by load_date desc

-- print (DATEADD(DAY,DATEDIFF(DAY,-1,@endDate),0))



/*
--BDESime
select [table] = 'delinquency_snapshot on ' + convert(varchar(10),@oneDay)
,[Loan Number],
[MSP DLQ STATUS],
[MTH STATUS NAME], *
from bdesime.[dbo].[delinquency_snapshot] 
where [Loan Number] = @loanNumber
and [Loan Date] = @oneDay

--BDE_Data
select [table] = 'delinquency on ' + convert(varchar(10),@oneDay)
,[ln_no],
[co_delq_cd], * 
from [dbo].[delinquency]
where [ln_no] = @loanNumber
and [Load_Date] = @oneDay

--BDE_Data
select [table] = 'delinquency_detail'
,[ln_no], [Load_Date],
[co_delq_cd], * 
from [delinquency]
where [ln_no] = @loanNumber
and [Load_Date] between  @startDate  and   eomonth(@endDate)


-- IS #850 Test Cases

-- Prepaid/Current
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0000997379' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0001020627' 
-- Pre-30
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0010776706' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0030645840' 
-- 30
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0011481785' 
-- 60
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0011451820' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0014194021' 
-- 90
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0014103378' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0030089502' 

-- 120+
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0030181259' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0030392567' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0015113681' 
exec sp_12Month_BorrowerPaymentHabits 'glen.banta@themoneysource.com','5/31/2017',  '0002139285' 
*/

