; WITH results AS (SELECT DISTINCT 
[EOM] = CONVERT(date, [LastDayOfMonth]), MonthYear = concat(DateName(month, CONVERT(date, [LastDayOfMonth])), ' ', DateName(year, (CONVERT(date, [LastDayOfMonth]))))
 FROM      [dbo].[DateDimension]
WHERE   CONVERT(date, [FirstDayOfMonth]) BETWEEN '8/1/2015' AND (CASE WHEN getdate() = EOMONTH(getDate()) THEN EOMonth(getdate()) ELSE DateAdd([m], - 1, EOMonth(getdate())) END))
    SELECT *, ROW_NUMBER() OVER (ORDER BY EOM ASC) AS [sid], ROW_NUMBER() OVER (ORDER BY EOM DESC) AS [sidDesc]
FROM     Results
ORDER BY EOM DESC
