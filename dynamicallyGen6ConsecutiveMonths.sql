declare @localstartdate date = '9/8/2016'

	-- dynamically generate 6 consecutive months from @startDate
	DECLARE @month date = CASE WHEN datepart(day,@localStartDate) < 16 
	THEN (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-1,0) + 14)) 
	ELSE (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)+0,0) + 14))
	END

	DECLARE @monthMinus1 date = CASE WHEN datepart(day,@localStartDate) < 16 
	THEN (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-2,0) + 14)) 
	ELSE (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-1,0) + 14))
	END

	DECLARE @monthMinus2 date = CASE WHEN datepart(day,@localStartDate) < 16 
	THEN (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-3,0) + 14)) 
	ELSE (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-2,0) + 14))
	END

	DECLARE @monthMinus3 date = CASE WHEN datepart(day,@localStartDate) < 16 
	THEN (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-4,0) + 14)) 
	ELSE (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-3,0) + 14))
	END

	DECLARE @monthMinus4 date = CASE WHEN datepart(day,@localStartDate) < 16 
	THEN (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-5,0) + 14)) 
	ELSE (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-4,0) + 14))
	END

	DECLARE @monthMinus5 date = CASE WHEN datepart(day,@localStartDate) < 16 
	THEN (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-6,0) + 14)) 
	ELSE (select convert(date,DATEADD(mm, DATEDIFF(m,0,@localStartDate)-5,0) + 14))
	END

	print @month print  @monthMinus1 print @monthMinus2 print @monthMinus3 print @monthMinus4 print @monthMinus5