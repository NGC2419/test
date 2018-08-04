USE [BDE_Data]
GO
-- grand total
SELECT  sum(pmt_am) as 'Payment Amount'  
FROM [dbo].[payment_tran] pt
where CAST(pmt_trans_dt as date) between '2/1/2017' and '2/14/2017'
and pmt_trans_cd in (170,171,172,173,174,175)
and pmt_principal_am > 0
group by concat(datename(month,convert(date,pmt_trans_dt)),' ', datepart(year,convert(date,pmt_trans_dt)) )

-- summary mtd
SELECT  'Payment Trans Month' = concat(datename(month,convert(date,pmt_trans_dt)),' ', datepart(year,convert(date,pmt_trans_dt)) ) 
	,pmt_trans_cd as 'Payment Trans Code'
	,sum(pmt_am) as 'Payment Amount'	
FROM [dbo].[payment_tran] pt
where CAST(pmt_trans_dt as date) between '2/1/2017' and '2/14/2017'
and pmt_trans_cd in (170,171,172,173,174,175)
and pmt_principal_am > 0
group by concat(datename(month,convert(date,pmt_trans_dt)),' ', datepart(year,convert(date,pmt_trans_dt)) )
,pmt_trans_cd
order by pmt_trans_cd

-- summary by date
SELECT convert(date,pmt_trans_dt) as 'Payment Trans Date'
	,pmt_batch_no as 'Payment Batch' 
	,pmt_trans_cd as 'Payment Trans Code'
	,sum(pmt_am) as 'Payment Amount'	
FROM [dbo].[payment_tran] pt
where CAST(pmt_trans_dt as date) between '2/1/2017' and '2/14/2017'
and pmt_trans_cd in (170,171,172,173,174,175)
and pmt_principal_am > 0
group by pmt_trans_dt
,pmt_batch_no
,pmt_trans_cd
order by pmt_trans_dt 
,pmt_batch_no
,pmt_trans_cd

-- detail		
SELECT ln_no as  'Loan Number'
	,convert(date,pmt_trans_dt) as 'Payment Trans Date'
	,pmt_batch_no as 'Payment Batch' 
	,pmt_trans_cd as 'Payment Trans Code'
	,pmt_am as 'Payment Amount'	
FROM [dbo].[payment_tran] pt
where CAST(pmt_trans_dt as date) between '2/1/2017' and '2/14/2017'
and pmt_trans_cd in (170,171,172,173,174,175)
and pmt_principal_am > 0
order by pmt_batch_no 

GO
