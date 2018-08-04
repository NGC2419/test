SELECT
 ExecutionLog.TimeStart,
 ExecutionLog.STATUS,
 RSCatalog.Path,
 RSCatalog.Name AS Report,
 ExecutionLog.UserName,
 ExecutionLog.Format,
 ExecutionLog.Parameters
FROM
 [ReportServer].[dbo].[ExecutionLog] ExecutionLog
 INNER JOIN [ReportServer].[dbo].[Catalog] RSCatalog
 ON ExecutionLog.ReportID = RSCatalog.ItemID
ORDER BY
 ExecutionLog.TimeStart DESC