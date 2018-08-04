USE BDE_Data
GO

UPDATE DateDimension
SET ProcessDate = b.ProcessDate, ProcessDay = b.ProcessDay, ProcessDatePriorMth = b.ProcessDatePriorMth, ProcessDayPriorMth = b.ProcessDayPriorMth
FROM DateDimension d
JOIN DateDimensionSD b ON d.[Date] = b.[Date]
WHERE d.[Date] >= '1/1/2018' OR d.[date] <= '9/1/2015' 

SELECT * FROM DateDimension WHERE [Date] >= '1/1/2018' OR [date] <= '9/1/2015' 

---->>>> STEP 1       ADD prior month ProcessDate values    <<<<----

-- ALTER Table DateDimensionSD drop column add IsLeapYearDay int
-- UPDATE DateDimensionSD SET IsLeapYearDay = CASE When day = 29 and month = 2 then 1 else 0 end  
-- select * from DateDimensionSD where isleapyearDay = 1

/* populate process dates
declare @i int = 1
,@loopDate date = '1/1/2018'

			WHILE @i <=  CASE WHEN (SELECT Distinct [isleapyearday] from DateDimensionSD WHERE [Year] = Year(@loopdate)) = 1 THEN 366 ELSE 365 END

				BEGIN
				SET @loopDate = (Select [Date] from DateDimensionSD where [DayOfYear] = @i and [Year] = Year(@loopdate) )

 DECLARE @startDate date = @loopDate
 
 DECLARE  	  @localBOM		date = dateadd(MONTH,-1,dateadd(day,+1,eomonth(@startDate)))  -- 1st of month
			, @localEOM		date = eomonth(@startDate)
			-- when @startDate falls on a holiday or weekend, use previous business date
			, @BizDate date = (SELECT max([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) < @StartDate AND [ProcessDate] IS NOT NULL) 
			-- last day of previous full month
			, @PriorEOM		date = eomonth(dateadd(MONTH,-1,@startDate))   -- last day of previous month
			, @PriorBOM     date = dateadd(MONTH,-2,dateadd(day,+1,eomonth(@startDate))) -- first day of previous month
            -- last day of previous prior month		
			, @PreviousPriorEOM	 date = eomonth(dateadd(MONTH,-2,@startDate))   -- last day of previous month
		
			-- when @PriorBizDate falls on a holiday or weekend, use previous business date
			, @PriorBizDate date = (SELECT max([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) < dateadd(month,-1,@StartDate) AND [ProcessDate] IS NOT NULL) 

			-- when @localstartDate falls in prior month use min business day of current month not falling on a holiday or weekend
			SET @BizDate = CASE WHEN @BizDate < @localBOM 
									   THEN (SELECT min([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) > @PriorEOM AND [ProcessDate] IS NOT NULL) 
									   ELSE @BizDate END
	
			-- when @PriorBizDate falls in prior month use min business day of current month not falling on a holiday or weekend
			SET @PriorBizDate = CASE WHEN @PriorBizDate < @PriorBOM 
									   THEN (SELECT min([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) > @PreviousPriorEOM AND [ProcessDate] IS NOT NULL) 
									   ELSE @PriorBizDate END
            -- validation
			--Print '@StartDate:          ' + convert(varchar(10),@startDate,101)
			--Print '@BizDate:            ' + convert(varchar(10),@BizDate,101)
			--Print '@PriorBizDate        ' + convert(varchar(10),@PriorBizDate,101)
			--Print '     '
			--Print '@localBOM:           ' + convert(varchar(10),@localBOM,101)
			--Print '@localEOM:           ' + convert(varchar(10),@localEOM,101)
			--Print '     '
			--Print '@PriorBOM:           ' + convert(varchar(10),@PriorBOM,101)
			--Print '@PriorEOM:           ' + convert(varchar(10),@PriorEOM,101)
			--Print '     '
			--Print '@PreviousPriorEOM:   ' + convert(varchar(10),@PreviousPriorEOM,101)

			-- Update the date dimension table with values for the prior month process dates
			--UPDATE DateDimensionSD
			--Set ProcessDate = @BizDate, ProcessDatePriorMth = @PriorBizDate
			--where [date] = @loopDate

			SELECT [DateKey], [Date], ProcessDate = @BizDate, ProcessDatePriorMth = @PriorBizDate, LoopDate = @loopDate
			  from DateDimensionSD 
			 where [date] = @loopDate
			   and [DayOfYear] = @i	
			   and [Year] = Year(@loopdate)
			--print @i

				SET @i = @i + 1
				END

				*/


---->>>>   STEP 2      populate process day number   <<<<----
/*
	UPDATE DateDimensionSD
 	SET ProcessDayPriorMth = b.ProcessDay
-- 	select distinct a.[Date],  a.[ProcessDate], a.ProcessDay, a.[ProcessDatePriorMth], ProcessDayPriorMth = b.ProcessDay
	From DateDimensionSD a
	JOIN (select distinct [Date], [ProcessDay] FROM DateDimensionSD) b -- #processDay ) b 
	ON a.[ProcessDatePriorMth] = b.[Date] 
	where a.[Date] >= '1/1/2018' OR a.[date] <= '9/1/2015' 

	SELECT distinct [Date], [ProcessDate], ProcessDay, [ProcessDatePriorMth], ProcessDayPriorMth
	  from DateDimensionSD 
	where [Date] >= '1/1/2018' OR [date] <= '9/1/2015' 
	ORDER BY [Date]

*/


---   EOF

-------   OLD  -------------

--declare @yyyymm int = 201501
--Declare @year int = convert(int,substring(convert(char(6),@yyyymm),1,4) )
--print  CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END

--/*     ADD ProcessDay values for current month   */

--UPDATE DateDimension 
--SET ProcessDay = p.ProcessDay
--FROM DateDimension d
--Join (
--		select [Date], [ProcessDay] =  ROW_NUMBER() OVER (ORDER BY [Date])
--			from DateDimension
--			WHERE isWeekend = 0 
--			  AND IsHoliday = 0 
--			  AND YYYYMM = @yyyymm
--			  ) p 
--	ON d.[Date] =p.[Date]
	
--	-- verify
--	--select date,yyyymm,processday from DateDimension where YYYYMM = @yyyymm
--	--select yyyymm,processday from DateDimension where processday = 0


--/*     ADD Number of Process Days values for current month   */

--Update DateDimension
--SET NbrProcessDays = p.NbrProcessDays
--From DateDimension d
--Join (Select YYYYMM, NbrProcessDays = max(processday) From DateDimension GROUP BY YYYYMM) p
--on d.yyyymm = p.yyyymm 


--/*     ADD Number of Process Days values for prior month   */

--UPDATE DateDimension
--set NbrProcessDaysPriorMth = d2.NbrProcessDaysPriorMth
--FROM DateDimension d
--JOIN (
--SELECT distinct C_YYYYMM = c.YYYYMM, c.NbrProcessDays, NbrProcessDaysPriorMth =p.NbrProcessDays, P_YYYYMM = p.YYYYMM
--FROM      (-- Get records from the Current month from the OriginalFact table.
--     SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth 
--      FROM  DateDimension
--      WHERE  yyyymm IN (@yyyymm)
--      ) c -- Current
--   CROSS APPLY (-- Get records from the Prior month.
--     SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth 
--      FROM  DateDimension
--      WHERE  yyyymm = convert(int,CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END)
--      ) p -- Prior
--   group by C.YYYYMM, c.NbrProcessDays,p.YYYYMM,p.NbrProcessDays
--   ) d2
--   ON d.YYYYMM = d2.C_YYYYMM

--SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth  from DateDimension where YYYYMM = @yyyymm
--SELECT distinct YYYYMM, ProcessDay, ProcessDayPriorMth, NbrProcessDays, NbrProcessDaysPriorMth  from DateDimension where YYYYMM = @yyyymm
--OR yyyymm = convert(int,CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END)

---- SELECT distinct YYYYMM, ProcessDay, ProcessDayPriorMth, NbrProcessDays, NbrProcessDaysPriorMth  from DateDimension where Year >= 1999 order by yyyymm

--/*     ADD prior month ProcessDay values   */
-- select Date, ProcessDay into CashProcessDays
--UPDATE DateDimension SET ProcessDayPriorMth = 0

--select * from DateDimension where YYYYMM = 201612

	-- verify	
 --select distinct [Date],ProcessDay, ProcessDayPriorMth, NbrProcessDays, NbrProcessDaysPriorMth, ProcessDate, ProcessDatePriorMth, YYYYMM,IsHoliday,IsWeekend
 --from DateDimension 
 ----where YYYYMM = convert(int,CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END)
 ----where NbrProcessDays = NbrProcessDaysPriorMth and year = 2016
 --where YYYYMM = 201510 --between 201509 and 201712

/* new columns added
ALTER TABLE DateDimension ADD ProcessDay int
ALTER TABLE DateDimension ADD ProcessDayPriorMth int
ALTER TABLE DateDimension ADD NbrProcessDays int
ALTER TABLE DateDimension ADD NbrProcessDaysPriorMth int
ALTER TABLE DateDimension  ADD ProcessDate Date
UPDATE DateDimension SET ProcessDate = Date WHERE ProcessDay <> 0
ALTER TABLE DateDimension  ADD ProcessDatePriorMth Date
ALTER TABLE DateDimension ADD ProcessDaysVariance int
ALTER TABLE DateDimension  ADD ExtraPriorMthDates Date
ALTER TABLE DateDimension ADD FirstDayOfPriorMonth AS dateadd(month,-1,FirstDayOfMonth)
ALTER TABLE DateDimension ADD LastDayOfPriorMonth AS EOMONTH(dateadd(month,-1,Date))

*/
 