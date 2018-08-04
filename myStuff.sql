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
SELECT-- distinct
   TE.[name],
   [Date] = convert(date,I.StartTime),
   I.LoginName,
   I.ObjectName,
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
   I.HostName,
--   I.IndexID,
--   I.IntegerData,
--   I.IsSystem,
--   I.LineNumber,
----   I.LoginName,
--   I.LoginSid,
--   I.NestLevel,
   I.NTDomainName,
   I.NTUserName,
--   I.ObjectID,
--   I.ObjectID2,
--   --I.ObjectName,
Convert(varchar(10), I.ObjectType) + N'-' + OT.subclass_name as ObjectType,
--   I.OwnerName,
--   I.ParentName,
--I.Permissions,
--   I.RequestID,
--   I.RoleName,
   I.ServerName,
--   I.SessionLoginName,
--   I.Severity,
   I.SPID
--   --I.StartTime,
--   I.State,
--   I.Success,
--   I.TargetLoginName,
--   I.TargetLoginSid,
--   I.TargetUserName,
--   ,I.TextData
--   I.TransactionID,
--   I.Type,
--   I.XactSequence
FROM
    sys.traces T 
	
	CROSS Apply sys.fn_trace_gettable(CASE WHEN CHARINDEX('_', T.[path]) <> 0
                              THEN SUBSTRING(T.PATH, 1, CHARINDEX('_', T.[path]) - 1) + '.trc'
                              ELSE T.[path]
                         End, T.max_files) I 
	JOIN sys.trace_events AS TE ON 
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
 I.DatabaseName in ('bdesime','bde_data','bde_data_test','bde_data_uat','bdesime_uat')
and hostname = 'TMS-CT-L-XT3LC2' 
 and objectname is not null --like '%rate%'
 and I.LoginName <> 'servicing'
 --or Convert(nvarchar(10), I.ObjectType) + N'-' + OT.subclass_name = 'u'
--AND   TE.NAME like '%delete%'
   ORDER By convert(date,StartTime) desc



--SELECT p.spid, p.status, p.hostname, p.loginame, p.cpu, last_batch, t.text FROM master.dbo.sysprocesses as p CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) t order by loginame 




/*
--------------------------------------------
LoginName				HostName
--------------------------------------------
bdereadonly				DESKTOP-TEBFE3S
EALOANS\saccount		UAT-SQL01
EALOANS\scheduled_tasks	UAT-SQL01
prader					TMS-CT-L-9T5PF2
rahuja					DESKTOP-DC8IB28
rgulati					TMS-CT-L-4PSQC2
rmcbride				DESKTOP-K6CO5PA
sa						NULL
sa						DESKTOP-K6CO5PA
ssabo					TMS-CT-L-002
TMS\bblanch				TMS-CT-L-1B2H72
TMS\rahuja				SIME-UTIL01
TMS\sdelaney			TMS-CT-L-XT3LC2
TMS\vbueno				UAT-SQL01
TMS\xmoja				UAT-SQL01

*/
