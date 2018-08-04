-- 
-- 
-- NOTE: PLEASE CONTACT S. DELANEY BEFORE CHANGING THIS PROGRAM
-- 
-- 


SELECT ServerName = CAST(serverproperty(N'Servername') AS sysname),
  p.spid, p.status, p.hostname, p.loginame, p.cpu, t.text
FROM   master.dbo.sysprocesses as p
    CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) t
	--where loginame = 'TMS\sdelaney'
	order by loginame

DECLARE @filename VARCHAR(255) 
SELECT @FileName = SUBSTRING(path, 0, LEN(path)-CHARINDEX('\', REVERSE(path))+1) + '\Log.trc'  
FROM sys.traces   
WHERE is_default = 1;  

SELECT  gt.StartTime, 
		gt.LoginName, 
       --gt.NTUserName, 
       --gt.NTDomainName, 
       te.Name AS EventName,
	   gt.ObjectName, 
	   gt.DatabaseName, 
	   gt.HostName, 
       gt.ApplicationName, 
       gt.SPID, 
       gt.EventClass, 
       gt.EventSubClass,      
       gt.TEXTData, 
       gt.EndTime, 
       gt.FileName, 
       gt.IsSystem
FROM [fn_trace_gettable](@filename, DEFAULT) gt 
JOIN sys.trace_events te ON gt.EventClass = te.trace_event_id 
WHERE --EventClass in (164) --AND gt.EventSubClass = 2
eventclass in (46,47,164) and category_id = 5
--and gt.starttime > '2016-09-26 00:00:00.000'
--where gt.ObjectName like '%multivaluesplit%'
and LoginName in ('tms\sdelaney', 'ssabo','jruiz', 'rmcbride','tms\rgulati','tms\rvillanueva','tms\rahuja','EALOANS\dwithers','tms\vbueno','tms\xmoja')
and databasename in ('bdesime','bde_data')
-- ORDER BY LoginName DESC, StartTime DESC; 
ORDER BY StartTime DESC, loginname; 


/*
sp_helptext 'sp_dt_bankruptcies_summary_rpt'
sp_helptext 'listclients'
use bde_data
use bdesime
ALTER PROCEDURE [dbo].[ListClients]
AS
BEGIN
	SELECT Client_Code,Client_Name,Reporting_Sort_Order
	from (
		SELECT * FROM BDESIME.dbo.fn_ListClients()
		) A 
	ORDER BY Reporting_Sort_Order,Client_Code
END

USE BDE_Data
--USE BDESIME
GO
 
 sp_helptext 'dbo.listclients'
SELECT Client_Code,Client_Name from dbo.fn_ListClients() ORDER BY 2

SELECT obj.Name SPName, sc.TEXT SPText
FROM sys.syscomments sc
INNER JOIN sys.objects obj ON sc.Id = obj.OBJECT_ID
WHERE sc.TEXT LIKE '%' + 'tbl_code_translation' + '%'
AND TYPE = 'P'

select distinct AppName from [BDE_Data].[dbo].[ApplicationExecution]
SELECT * FROM [BDE_Data].[dbo].[ApplicationExecution]  where convert(date,loaddate) = Dateadd(day,-1,convert(date,getdate())) 

SELECT JobID, StartDate, ComputerName, RequestName, RequestPath, SUSER_SNAME(Users.[Sid]), Users.[UserName], Description, 
    Timeout, JobAction, JobType, JobStatus, Users.[AuthType]
FROM ReportServer.dbo.RunningJobs INNER JOIN Users 
ON RunningJobs.UserID = Users.UserID

select ROUTINE_NAME, ROUTINE_SCHEMA from INFORMATION_SCHEMA.ROUTINES where ROUTINE_BODY <> 'EXTERNAL' Order By 1

exec [dbo].[sp_portfolio_summary_rpt] '8/5/2016','all','all'

Select DISTINCT  [LETTER ID],[LOAN NUMBER], [LETTER DATE] INTO #LW from [BDESIME].[dbo].letter_writer
where [LETTER ID] in ('XP001' , 'XP701', 'GE530')
and [LETTER DATE] BETWEEN dateadd(MONTH, datediff(MONTH, 0, convert(date,@local_enddate)) - 0, 0) and convert(date,@local_enddate)

Select  lw.[LOAN NUMBER] ,[LETTER DATE] , [FIRST PRINCIPAL BALANCE] as UPB ,[LETTER ID]
INTO #POR
from #LW lw
JOIN  [BDESIME].[dbo].[delinquency_snapshot] d on  d.[LOAN NUMBER] = lw.[LOAN NUMBER] 
--JOIN #property p on p.[LOAN NUMBER] = d.[LOAN NUMBER]
	INNER JOIN bde_data.dbo.investor_client ic ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
						AND ic.client IN (SELECT b.item FROM BDESime.dbo.fnMultiValueSplit(@Client_Code, ',') b) 
where  [LOAN DATE] = [LETTER DATE]
--and [FIRST PRINCIPAL BALANCE] > 0

	Select  [LETTER DATE], [LETTER ID] 
	,Count(*) as 'poCount' 	
	, SUM(UPB) as UPB
	,1 as ID
	from #POR
	where UPB = 0 
	group by [LETTER ID], [LETTER DATE]

	UNION 	
	
	Select  [LETTER DATE],  [LETTER ID] 
	,Count(*) as 'poCount' 	
	, SUM(UPB) as UPB
	,2 as ID
	from #POR
	where UPB > 0 
	group by [LETTER ID], [LETTER DATE]

	--Select * from #LW
	sp_who2 
Drop table #POR
--Drop table #property
Drop table #LW


SELECT * FROM sys.all_objects WHERE type in ('TF', 'FN', 'IF', 'FS', 'FT') ORDER BY [Name] ASC

*/

--EXEC [dbo].[sp_DLQ_month_to_month] '10/31/2016' ,'9/30/2016' , '%', 'TMS000,EVB001',0
--EXEC [dbo].[sp_portfolio_summary_rpt] '10/31/2016' , 'TMS000,EVB001', '%' 



--select ln_no,dsb_trans_dt,count(*) from ufnGetMax_escrow_disb_tran ('11/02/2016')  
--where dsb_trans_cd ='310' and dsb_trans_dt not between '08/01/2016' and '09/02/2016' group by ln_no,dsb_trans_dt

--select * from ufnGetMax_escrow_disb_tran ('11/02/2016') where ln_no='0002066926'     0012233946'0030206841'


	--Select a.[LOAN NUMBER],[BKR DEBTOR ATTORNEY ID], [BKR MORTGAGEE ATTORNEY ID] from (
	--Select [LOAN NUMBER],MAX([BKR SETUP DATE]) as [BKR SETUP DATE] from BDESIME.dbo.bankruptcy --where [LOAN NUMBER] = '0010776144'
	--group by [LOAN NUMBER]) as a
	--JOIN (Select [LOAN NUMBER],[BKR DEBTOR ATTORNEY ID],[BKR MORTGAGEE ATTORNEY ID], [BKR SETUP DATE] from BDESIME.dbo.bankruptcy) b
	--on a.[BKR SETUP DATE] = b.[BKR SETUP DATE]and a.[LOAN NUMBER] = b.[LOAN NUMBER]
	--where a.[LOAN NUMBER] =0010776144