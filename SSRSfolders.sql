SELECT Folder = RSCatalog.[Path],
 Report = RSCatalog.Name 
 FROM [ReportServer2016].[dbo].[ExecutionLog] ExecutionLog
 INNER JOIN [ReportServer2016].[dbo].[Catalog] RSCatalog
 ON ExecutionLog.ReportID = RSCatalog.ItemID
WHERE RSCatalog.[Path]  <> ''
ORDER BY RSCatalog.[Path], RSCatalog.Name asc
