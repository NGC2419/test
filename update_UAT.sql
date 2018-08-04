use BDE_Data
go

-- UAT EVB001	GNMA
--PROD EVB001 EVB001
select distinct client, investor, inv_cat, inv_id from investor_client --where client = 'evb001'

select distinct client, investor from portfolio_summary_investor where client = 'evb001'

select distinct [loan date], iv_cat_cd, owner_name, count(distinct [loan number]) 
from bdesime.dbo.delinquency_snapshot 
where [loan date] in ('11/30/2016') and owner_name = 'fnma' 
group by [loan date], iv_cat_cd, owner_name 
order by [loan date], owner_name, iv_cat_cd 

/*
drop table #clientloans
select distinct l.ln_no, l.iv_id, l.iv_cat_cd, Investor
	INTO #ClientLoans
 	FROM dbo.ufnGetMax_loan('11/30/2016') l
	INNER JOIN investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit('tms000', ',') b) 
	AND ic.investor IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit('fnma', ',') b) 

	select count(*) from #clientloans  -- 10983


		  Select [loan date] = convert(date,d.[loan date])
				,d.[Loan Number]
				,c.[Investor]
				,d.proper_status
				,d.[MTH STATUS NAME]
				,d.[FIRST PRINCIPAL BALANCE]
		 --into #delinquency_snapshot
				 FROM #ClientLoans c  
				 INNER JOIN bdesime.dbo.delinquency_snapshot d (nolock) ON c.[ln_no] = d.[LOAN NUMBER] AND c.iv_cat_cd = d.iv_cat_cd
				  -- for date selected
				  --where convert(date,d.[loan date]) = convert(date,'11/30/2016')
				-- from first of month through date selected
				where convert(date,d.[loan date]) BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,'11/30/2016')) - 0, 0) and convert(date,'11/30/2016')
					AND c.investor IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit('tms000', ',') b) 
					 and  d.[FIRST PRINCIPAL BALANCE] <> 0 
				  group by d.[LOAN DATE]
				,c.[Investor]
				,d.[Loan Number]
				,d.proper_status
				,d.[MTH STATUS NAME]
				,d.[FIRST PRINCIPAL BALANCE]

				-- UAT EVB001	GNMA


--PROD EVB001 EVB001
select distinct client, investor from investor_client where client = 'evb001'
select distinct client, investor from portfolio_summary_investor where client = 'evb001'

select top 3 * from bdesime.dbo.delinquency_snapshot

select distinct  owner_name, loans = count([loan number])  -- ,iv_cat_cd 
from bdesime.dbo.delinquency_snapshot 
where owner_name = 'fnma' and [loan date]= '11/30/2016'
and [first principal balance] > 0  -- 10057 on 11/30  -- 10041 on 11/29 
and proper_status not like '%reo%'
group by 

select * from portfolio_summary where sortid in(20161129,20161130)
select * from portfolio_summary_investor where sortid in (20161129,20161130)

*/



 --where c = 'evb001'

 -- Table was loaded in Production and imported to UAT so IF EVB001 is different need to change UAT
 --update portfolio_summary_investor
 --set investor = 'GNMA'
 --where client = 'evb001' and investor = 'evb001'
