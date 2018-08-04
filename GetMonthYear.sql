SELECT DISTINCT BOM = d1.FirstDayOfMonth, EOM = d1.LastDayOfMonth, MonthYear = concat(d1.[MonthName],' ',convert(char(4),d1.[Year]))
, d2.[sid]
FROM     DateDimension d1
join (
SELECT ROW_NUMBER() OVER(ORDER BY FirstDayOfMonth ASC) AS sid, FirstDayOfMonth = max(FirstDayOfMonth)
from DateDimension
WHERE  (FirstDayOfMonth >= '8/1/2015') AND (LastDayOfMonth <= EOMONTH(GETDATE(), - 1)) OR
                  (LastDayOfMonth >= '8/1/2015') AND (FirstDayOfMonth <= EOMONTH(GETDATE(), - 1))
group by FirstDayOfMonth

) d2 on d1.FirstDayOfMonth = d2.FirstDayOfMonth
WHERE  (d1.FirstDayOfMonth >= '8/1/2015') AND (d1.LastDayOfMonth <= EOMONTH(GETDATE(), - 1)) OR
                  (d1.LastDayOfMonth >= '8/1/2015') AND (d1.FirstDayOfMonth <= EOMONTH(GETDATE(), - 1))
ORDER BY d2.[sid] DESC
