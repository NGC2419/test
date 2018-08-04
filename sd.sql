-- select [DateTime], [User],[Item],[DisplayName] FROM simeportal.dbo.recentitems where item like '/1) In Process/Susan/%' ORDER BY convert(date,[DateTime]) desc   -- displays sime user that ran report
--SELECT CAST(serverproperty(N'Servername') AS sysname) AS [Name], 'Server[@Name=' + quotename(CAST(          serverproperty(N'Servername')         AS sysname),'''') + ']' + '/JobServer' AS [Urn] ORDER BY [Name] ASC
--displays what's executing
SELECT p.spid, p.status, p.hostname, p.loginame, p.cpu, last_batch, t.text FROM master.dbo.sysprocesses as p CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) t order by loginame 

;With cteObjectTypes AS
   (
   SELECT
      TSV.trace_event_id,
      TSV.subclass_name,
      TSV.subclass_value
   FROM
      sys.trace_subclass_values AS TSV JOIN
      sys.trace_columns AS TC ON
         TSV.trace_column_id = TC.trace_column_id 
   WHERE
      TC.[name] = 'ObjectType'
   ),
   cteEventSubClasses AS
   (
   SELECT
      TSV.trace_event_id,
      TSV.subclass_name,
      TSV.subclass_value
   FROM
      sys.trace_subclass_values AS TSV JOIN
      sys.trace_columns AS TC ON
         TSV.trace_column_id = TC.trace_column_id 
   WHERE
      TC.[name] = 'EventSubClass'
   )
SELECT distinct
   TE.[name],
   [Date] = convert(date,I.StartTime),
   I.LoginName,
   I.ObjectName
--   Convert(nvarchar(10), I.ObjectType) + N'-' + OT.subclass_name as ObjectType,
--   I.ApplicationName,
--   I.BigintData1,
--   I.ClientProcessID,
--   I.ColumnPermissions,
--   I.DatabaseID,
--   I.DatabaseName,
--   I.DBUserName,
--   I.Duration,
--   I.EndTime,
--   I.Error,
--   I.EventSequence,
--   Convert(nvarchar(10), I.EventSubClass) + N'-' + ESC.subclass_name as EventSubClass,
--   I.FileName,
--   I.HostName,
--   I.IndexID,
--   I.IntegerData,
--   I.IsSystem,
--   I.LineNumber,
----   I.LoginName,
--   I.LoginSid,
--   I.NestLevel,
--   I.NTDomainName,
--   I.NTUserName,
--   I.ObjectID,
--   I.ObjectID2,
--   --I.ObjectName,
--   --Convert(nvarchar(10), I.ObjectType) + N'-' + OT.subclass_name as ObjectType,
--   I.OwnerName,
--   I.ParentName,
--   I.Permissions,
--   I.RequestID,
--   I.RoleName,
--   I.ServerName,
--   I.SessionLoginName,
--   I.Severity,
--   I.SPID,
--   --I.StartTime,
--   I.State,
--   I.Success,
--   I.TargetLoginName,
--   I.TargetLoginSid,
--   I.TargetUserName,
--   I.TextData,
--   I.TransactionID,
--   I.Type,
--   I.XactSequence
FROM
    sys.traces T CROSS Apply 
    sys.fn_trace_gettable(CASE WHEN CHARINDEX('_', T.[path]) <> 0
                              THEN SUBSTRING(T.PATH, 1, CHARINDEX('_', T.[path]) - 1) + '.trc'
                              ELSE T.[path]
                         End, T.max_files) I JOIN
    sys.trace_events AS TE ON 
      I.EventClass = TE.trace_event_id LEFT JOIN
   cteEventSubClasses AS ESC ON
      TE.trace_event_id = ESC.trace_event_id And
      I.EventSubClass = ESC.subclass_value LEFT JOIN
   cteObjectTypes AS OT ON 
      TE.trace_event_id = OT.trace_event_id AND
      I.ObjectType = OT.subclass_value
--WHERE ObjectName like '%monthly%'
  --where T.is_default = 1 
  --AND   TE.NAME = 'Objecteleted'
where 
--and objectname = 'sp_dt_finance_summary_rpt'
 I.DatabaseName in ('bdesime','bde_data')
 and objectname like 'sp_%'
 --or Convert(nvarchar(10), I.ObjectType) + N'-' + OT.subclass_name = 'u'
--AND   TE.NAME like '%delete%'
   ORDER By convert(date,StartTime) desc

/*	

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
 gt.objectName NOT LIKE '_WA_Sys_%'
 and te.Name not like 'Audit%'
--eventclass in (46,47,164) and category_id = 5
--and gt.starttime > '2016-09-26 00:00:00.000'
--and gt.ObjectName like '%inbound_Skill_Level_Call_Stats'
and databasename in ('bdesime','bde_data')
--and loginname NOT IN ('EALOANS\scheduled_tasks','servicing')
-- ORDER BY LoginName DESC, StartTime DESC; 
ORDER BY StartTime DESC, loginname; 

*/



/*
 listclients 

select * from portfolio_summary order by loanDate desc

declare @filename nvarchar(100)
set @filename = 'c:\test.' + convert(varchar(10),getdate(),102) + '.xls'
print @filename

declare @a datetime
Select @a = convert(varchar(30),dateadd(month,-1,EOMONTH(getdate())), 120)

insert into OPENROWSET(
   'Microsoft.Jet.OLEDB.4.0', 
   'Excel 8.0;Database=d:\export\sales.xls;;HDR=YES', 
   'SELECT * FROM [Sheet1$]')
exec [dbo].[sp_portfolio_summary_by_state] @a, 'TMS000','CA'


select * from bde_data.dbo.portfolio_summary order by loandate desc

*/
/*
 select * from portfolio_summary order by loanDate desc

declare @filename nvarchar(100)
set @filename = 'c:\test.' + convert(varchar(10),getdate(),102) + '.xls'
print @filename

declare @a datetime
Select @a = convert(varchar(30),dateadd(month,-1,EOMONTH(getdate())), 120)

insert into OPENROWSET(
   'Microsoft.Jet.OLEDB.4.0', 
   'Excel 8.0;Database=d:\export\sales.xls;;HDR=YES', 
   'SELECT * FROM [Sheet1$]')
exec [dbo].[sp_portfolio_summary_by_state] @a, 'TMS000','CA'


select * from bde_data.dbo.portfolio_summary order by loandate desc

For SSRS LoanDetail URL
DataSet   query:   SELECT dbo.ufnGetgetloanlink() AS URL
Parameter:   hidden Parameter named URL
Report field  ="javascript:void(window.open('"+ Parameters!URL.Value & Fields!Loan_Number.Value + "','_blank'))"

r TMS-CT-L-4PSQC2            
m DESKTOP-K6CO5PA                                                                                                                                                                                                                      
s  TMS-CT-L-002   Sime2-SSRS-UAT
*/
--Select top 10 * from     collection_contact --where coll_cont_ty in ('AT1', 'AT2', 'AT3', 'ATP') 

--select top 10 [Loan Number]
--	  , [commentDate] = concat(convert(date,[long comment date]),' ' , convert(time,[long comment time]))
--	  , Comments = isnull(concat([long comment text line 01],' ', [long comment text line 02],' ', [long comment text line 03],' ', [long comment text line 04]) ,' ')
--	  , *
--	   from bdesime.dbo.long_comment 
----	   where [loan number] IN (SELECT Distinct [Loan Number] From #PartA) 
--	-- 6/2/2017  SD added REO workstation
--	   where [LONG COMMENT WORKSTATION CODE] = 'R' 


--select * from Portfolio_Summary order by loandate desc