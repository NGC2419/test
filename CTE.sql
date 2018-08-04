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
where objectname is not null -- = 'sp_dt_finance_summary_rpt'
and  I.DatabaseName in ('bdesime','bde_data')
and (objectname not like '_WA_Sys_%'
and objectname like 'sp_%')
 and I.LoginName <> 'servicing'
   ORDER By convert(date,StartTime) desc

--sp_helptext 'sp_portfolio_by_state'