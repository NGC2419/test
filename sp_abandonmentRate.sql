-- Detail
SELECT TOP 100000  
[dbo].[five9_activity].[CAMPAIGN] AS 'Campaign', [dbo].[five9_activity].[YEAR] AS 'Year', [dbo].[five9_activity].[MONTH] AS 'Month', COUNT(DISTINCT [dbo].[five9_activity].[CALL ID]) AS 'All Calls', SUM([dbo].[five9_activity].[ABANDONED]) AS 'Abandoned Calls', AVG(CAST([dbo].[five9_activity].[ABANDONED] AS float)) AS 'Abandonment Rate'
FROM [dbo].[five9_activity] WITH(NOLOCK) 
WHERE ([dbo].[five9_activity].[TIMESTAMP] BETWEEN '2016-09-01T00:00:00.000' AND '2016-09-30T23:59:59.998') AND (([dbo].[five9_activity].[ABANDONED] = 0) OR (([dbo].[five9_activity].[ABANDONED] = 1) AND ([dbo].[five9_activity].[TIME TO ABANDON] > '00:00:30')))
GROUP BY [dbo].[five9_activity].[CAMPAIGN], [dbo].[five9_activity].[YEAR], [dbo].[five9_activity].[MONTH]
ORDER BY [dbo].[five9_activity].[CAMPAIGN] ASC, [dbo].[five9_activity].[YEAR] ASC, [dbo].[five9_activity].[MONTH] ASC, COUNT(DISTINCT [dbo].[five9_activity].[CALL ID]) ASC;

-- Detail Totals
SELECT SUM([All Calls]) AS 'All Calls', SUM([Abandoned Calls]) AS 'Abandoned Calls', AVG(CAST([Abandonment Rate] AS float)) AS 'Abandonment Rate'
FROM (
SELECT TOP 100000  
[dbo].[five9_activity].[CAMPAIGN] AS 'Campaign', [dbo].[five9_activity].[YEAR] AS 'Year', [dbo].[five9_activity].[MONTH] AS 'Month', COUNT(DISTINCT [dbo].[five9_activity].[CALL ID]) AS 'All Calls', SUM([dbo].[five9_activity].[ABANDONED]) AS 'Abandoned Calls', AVG(CAST([dbo].[five9_activity].[ABANDONED] AS float)) AS 'Abandonment Rate',[dbo].[five9_activity].[CAMPAIGN] as '__order1',[dbo].[five9_activity].[YEAR] as '__order2',[dbo].[five9_activity].[MONTH] as '__order3'
FROM [dbo].[five9_activity] WITH(NOLOCK) 
WHERE ([dbo].[five9_activity].[TIMESTAMP] BETWEEN '2016-09-01T00:00:00.000' AND '2016-09-30T23:59:59.998') AND (([dbo].[five9_activity].[ABANDONED] = 0) OR (([dbo].[five9_activity].[ABANDONED] = 1) AND ([dbo].[five9_activity].[TIME TO ABANDON] > '00:00:30')))
GROUP BY [dbo].[five9_activity].[CAMPAIGN], [dbo].[five9_activity].[YEAR], [dbo].[five9_activity].[MONTH]
ORDER BY [dbo].[five9_activity].[CAMPAIGN] ASC, [dbo].[five9_activity].[YEAR] ASC, [dbo].[five9_activity].[MONTH] ASC
) AS q1 
 GROUP BY [__order1],[__order2],[__order3]
ORDER BY [__order1],[__order2],[__order3];