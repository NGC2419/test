USE BDE_Data
--USE BDESIME
GO

SELECT distinct obj.Name SPName--, sc.TEXT SPText
FROM sys.syscomments sc
INNER JOIN sys.objects obj ON sc.Id = obj.OBJECT_ID
WHERE sc.TEXT LIKE '%proper_status%'
AND TYPE IN ('P','f','u')

/*
select [user 50 position field 1a] from bdesime.dbo.user_defined where [loan number ] = '0008070500'
--displays what's executing
--SELECT p.spid, p.status, p.hostname, p.loginame, p.cpu, last_batch, t.text FROM master.dbo.sysprocesses as p CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) t order by loginame 

SELECT * from sys.objects where modify_date > '8/15/2016' or create_date  > '8/15/2016' 
sp_helptext 'sp_dt_lm_modification_trials_summary'
select [Table] = 'delinquency_snapshot', [loan number], [Mth Status Name], proper_status, [Man Code], [MSP DLQ Status], [loan date] from [BDESIME].[dbo].[delinquency_snapshot] 
where [mth status name] <> [proper_status] and [loan date] = '10/25/2016' and [loan number]  = '0010788933' 
select [Table] = 'delinquency', ln_no, co_man_cd, co_delq_cd, load_date from bde_data.dbo.ufn_getmax_delinquency('10/25/2016') where [ln_no]   = '0010788933' 
select [Table] = 'loan', ln_no, co_man_cd, load_date from bde_data.dbo.ufngetmax_loan('10/25/2016') where [ln_no]   = '0010788933' 
	

declare @localEndDate date = convert(date,dateadd(d,15 - datepart(d,getdate()),getdate()))
declare @localEndDatePrev date = convert(date, dateadd(month,-1,@localEndDate))

select ln_no, ln_nxt_pmt_due_dt, ln_tot_pymt_due_am, ln_nxt_pmt_due_dt,co_man_cd, load_date 
from bde_data.dbo.ufngetmax_loan(@localEndDate) 
where ln_1st_prin_ba > 0 and [ln_no] = '0001049006' 
UNION
select ln_no, ln_nxt_pmt_due_dt, ln_tot_pymt_due_am, ln_nxt_pmt_due_dt,co_man_cd, load_date 
from bde_data.dbo.ufngetmax_loan(@localEndDatePrev) 
where ln_1st_prin_ba > 0 and [ln_no] = '0001049006' 
*/

--sp_helptext 'sp_MSR_Evaluation_Data'






--- exec sp_subsrv_ActiveREO '02/27/2017','TMS000,EVB001'



--Select 'Claims' as 'StaticData'
--		,[LoanNumber]=(r.ln_no)
--		--,[PerREO]=CONVERT(DECIMAL(10,2),100.0 * isnull(Count(ln.ln_no),0) / isnull( replace(@TotalCount,0,1) ,1),1)/100
--		,[reo_template_id] 
--		,rs.[RS STEP CODE]
--		,rs.[RS ACTUAL COMPLETION DATE]
--		,reo_processor_id
--		,ln.ln_1st_prin_ba
--	  from #MaxLoans ln
--	  inner join dbo.ufnGetMax_reo('02/24/2017') r on r.[ln_no] = ln.[ln_no]
--	  LEFT JOIN bdesime.dbo.reo_steps rs on rs.[Loan Number]=r.ln_no
--where r.reo_status_cd='A' and 
--(r.[reo_template_id] ='3PSALE'--in('FHMPOST','FNMAPST','VAPOST')
--and rs.[RS STEP CODE]='811' and rs.[RS ACTUAL COMPLETION DATE] is not null)
--or (r.[reo_template_id] ='FHAPOST'
--and rs.[RS STEP CODE]='932' and rs.[RS ACTUAL COMPLETION DATE] is not null)
--or (r.[reo_template_id] in('MARKET','USDA','VAMRKT')
--and rs.[RS STEP CODE]='R65' and rs.[RS ACTUAL COMPLETION DATE] is not null)
--or(r.[reo_template_id] in ('FHMPOST','FNMAPST')
--and rs.[RS STEP CODE]='443' and rs.[RS ACTUAL COMPLETION DATE] is not null)
--or (r.[reo_template_id] = ('VAPOST')
--and rs.[RS STEP CODE]='R43' and rs.[RS ACTUAL COMPLETION DATE] is not null)



--Select 'REO Non Liquidation' as 'StaticData'
--		,[LoanNumber]=(r.ln_no)
--		--,[PerREO]=CONVERT(DECIMAL(10,2),100.0 * isnull(Count(ln.ln_no),0) / isnull( replace(@TotalCount,0,1) ,1),1)/100
--		,[reo_template_id] 
--		,rs.[RS STEP CODE]
--		,rs.[RS ACTUAL COMPLETION DATE]
--		,reo_processor_id
--		,ln.ln_1st_prin_ba
--	  from #MaxLoans ln
--	  inner join dbo.ufnGetMax_reo('02/24/2017') r on r.[ln_no] = ln.[ln_no]
--	  LEFT JOIN bdesime.dbo.reo_steps rs on rs.[Loan Number]=r.ln_no
--where r.reo_status_cd='A' and 
--(r.[reo_template_id] ='3PSALE'
--and rs.[RS STEP CODE]='811' and rs.[RS ACTUAL COMPLETION DATE] is null)
--or (r.[reo_template_id] ='FHAPOST'
--and rs.[RS STEP CODE]='932' and rs.[RS ACTUAL COMPLETION DATE] is null)
--or (r.[reo_template_id] = ('VAPOST')
--and rs.[RS STEP CODE]='R43' and rs.[RS ACTUAL COMPLETION DATE] is null)
--or(r.[reo_template_id] in ('FHMPOST','FNMAPST')
--and rs.[RS STEP CODE]='443' and rs.[RS ACTUAL COMPLETION DATE] is null)


--select r.[reo_template_id] 
--		,ln.ln_1st_prin_ba
--	  from #MaxLoans ln
--	  inner join dbo.ufnGetMax_reo('02/24/2017') r on r.[ln_no] = ln.[ln_no]
--	  where r.[reo_template_id] ='FHAPOST'

-- sp_helptext 'sp_svc_Corporate_Advance_Payee_rpt'

