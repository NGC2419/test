USE ReportServer
GO
--=====================================================

DECLARE @DateFrom Date
DECLARE @DateTo Date
SET @DateFrom = '2016-01-01'
SET @DateTo = '2016-06-30'
 

SELECT Name
	, DATEPART(Hour, TimeStart) AS ReportYear
    , DATEPART(Month, TimeStart) AS ReportMonth
    , DATEPART(Day, TimeStart) AS ReportDay
    , DATEPART(Hour, TimeStart) AS ReportHour
    , Type
    , COUNT(Name) AS ExecutionCount
    , SUM(TimeDataRetrieval) AS TimeDataRetrievalSum
    , SUM(TimeProcessing) AS TimeProcessingSum
    , SUM(TimeRendering) AS TimeRenderingSum
    , SUM(ByteCount) AS ByteCountSum
    , SUM([RowCount]) AS RowCountSum
FROM
(
    SELECT TimeStart, Catalog.Type, Catalog.Name, TimeDataRetrieval,
  TimeProcessing, TimeRendering, ByteCount, [RowCount]
    FROM
    Catalog INNER JOIN ExecutionLog ON Catalog.ItemID =
       ExecutionLog.ReportID LEFT OUTER JOIN
    Users ON Catalog.CreatedByID = Users.UserID
    WHERE ExecutionLog.TimeStart BETWEEN @DateFrom AND @DateTo
) AS RE
WHERE Name <> ''
GROUP BY
      DATEPART(Hour, TimeStart)
    , DATEPART(Month, TimeStart)
    , DATEPART(Day, TimeStart)
    , DATEPART(Hour, TimeStart)
    , Type
	, Name
ORDER BY 
      ReportYear
    , ReportMonth
    , ReportDay
    , ReportHour
    , Type


--=====================================================
--Top Most Frequent:
--=====================================================

SELECT TOP 20
      COUNT(Name) AS ExecutionCount
    , Name
    , SUM(TimeDataRetrieval) AS TimeDataRetrievalSum
    , SUM(TimeProcessing) AS TimeProcessingSum
    , SUM(TimeRendering) AS TimeRenderingSum
    , SUM(ByteCount) AS ByteCountSum
    , SUM([RowCount]) AS RowCountSum
FROM
(
    SELECT TimeStart, Catalog.Type, Catalog.Name,
      TimeDataRetrieval, TimeProcessing, TimeRendering, ByteCount, [RowCount]
    FROM
    Catalog INNER JOIN ExecutionLog ON Catalog.ItemID = ExecutionLog.ReportID
     WHERE ExecutionLog.TimeStart BETWEEN @DateFrom AND @DateTo AND Type = 2
) AS RE
GROUP BY
        Name
ORDER BY 
        COUNT(Name) DESC
      , Name

--=====================================================
-- Unused Reports:
--=====================================================

SELECT Name, Path, UserName
FROM Catalog INNER JOIN dbo.Users ON Catalog.CreatedByID = Users.UserID
WHERE Type = 2 AND
    Catalog.ItemID NOT IN
    (
       SELECT ExecutionLog.ReportID
        FROM ExecutionLog
         WHERE ExecutionLog.TimeStart BETWEEN @DateFrom AND @DateTo
    ) 
    ORDER BY Name


--=====================================================
