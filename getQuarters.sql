
select [Date]
		, [Quarter]
		, [FirstDayOfQuarter]
		, [LastDayOfQUarter]
		, [FirstDayofPreviousQuarter]		= convert(date,DATEADD(QUARTER, DATEDIFF(QUARTER, 0, FirstDayOfQuarter) - 1, 0) )
		, [LastDayOfPreviousQuarter]		= convert(date, DATEADD(s, -1, DATEADD(qq, DATEDIFF(qq, 0, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, FirstDayOfQuarter) - 0, 0)     ), 0)))
		, [FirstDayofPreviousPriorQuarter]	= convert(date,DATEADD(QUARTER, DATEDIFF(QUARTER, 0, FirstDayOfQuarter) - 2, 0) )
		, [LastDayOfPreviousPriorQuarter]	= convert(date, DATEADD(s, -1, DATEADD(qq, DATEDIFF(qq, 0, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, FirstDayOfQuarter) - 1, 0)     ), 0)))
	from datedimension where date	= '5/17/2017' --convert(date,getdate())