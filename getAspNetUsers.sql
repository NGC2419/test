select * FROM     simemembership.dbo.AspNetUsers AS U WITH (nolock)



SELECT  MinDate = MIN(CreatedOn)
	, [Date]  = CONVERT(CHAR(3), DATENAME(MONTH, CreatedOn)) + ' ' + CONVERT(CHAR(4), DATENAME(YEAR, CreatedOn))
	,[Count] =  COUNT(CreatedOn) 
FROM     simemembership.dbo.AspNetUsers AS U WITH (nolock)
WHERE  (CAST(CreatedOn AS date) BETWEEN DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 3, 0) 
    AND EOMONTH(DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0)))
GROUP BY CONVERT(CHAR(4), DATENAME(YEAR, CreatedOn))
               , CONVERT(CHAR(3), DATENAME(MONTH, CreatedOn))
--ORDER BY min_date