

select [MonthName]
		, [Year] 
		,MonthYear 
		,DaysInMonth
		--,sid
from SSRSmonthYear 
where year <= datepart(year,getdate()) and MonthName <= DATENAME(mm,getdate()) 

--order by sid desc

update ssrsmonthyear 
set EOM = convert(date,concat(case when month in (1,2,3,4,5,6,7,8,9) THEN concat('0',month) else month end,'/', daysinmonth,'/', year) ) from SSRSmonthYear


-- select EOM = convert(date,concat(case when month in (1,2,3,4,5,6,7,8,9) THEN concat('0',month) else month end,'/', daysinmonth,'/', year) ) from SSRSmonthYear





USE BDE_Data
GO

select * from SSRScalendar

CREATE TABLE dbo.SSRScalendar (      
   the_date      datetime NOT NULL     
)      
GO    



 
     
ALTER TABLE dbo.SSRScalendar      
ADD     
   CONSTRAINT pk_calendar PRIMARY KEY CLUSTERED (the_date)      
     WITH FILLFACTOR = 100      
GO      
INSERT INTO dbo.SSRScalendar (the_date)      
SELECT the_date      
FROM   (      
        SELECT DateAdd(dd, (a.number * 256) + b.number, 0) As [the_date]      
        FROM     (      
                SELECT number      
                FROM   master..spt_values      
                WHERE  type = 'P'     
                AND    number <= 255      
               ) As [a]      
         CROSS     
          JOIN (      
                SELECT number      
                FROM   master..spt_values      
                WHERE  type = 'P'     
                AND    number <= 255      
               ) As [b]      
       ) As [dates]      
GO   
select * from SSRScalendar