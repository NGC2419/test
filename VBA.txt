="Projected Escrow beginning " & FormatDateTime(DateAdd("m",1,CDate(Parameters!startDate.Value)),DateFormat.ShortDate) + " Clients: " & IIF(Parameters!Client_Code.Count=CountRows("Clients"),"All",IIF(Parameters!Client_Code.Count = 1 , Parameters!Client_Code.Label(0), JOIN( Parameters!Client_Code.Label,", ")))

=======================================================================================================
=IIF(Fields!Skill.Value = Previous(Fields!Skill.Value),"",Fields!Skill.Value)
=======================================================================================================

=IIF(Parameters!Client_Code.Count=CountRows("clients"),"All",IIF(Parameters!Client_Code.Count = 1 , Parameters!Client_Code.Label(0), JOIN( Parameters!Client_Code.Label,", ")))

="Agent Groups: " & IIF(Parameters!AgentGroup.Count=CountRows("agentGroups"),"All",IIF(Parameters!AgentGroup.Count = 1 , Parameters!AgentGroup.Label(0), JOIN( Parameters!AgentGroup.Label,", ")))

=======================================================================================================

split multi-value parameter for predicate IN clause

WHERE  Agent_Group IN  (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@AgentGroup, ',') b)  

=SPLIT(JOIN(Parameters!clientCode.Value,","),",")

=======================================================================================================
Alternating Row Color

=IIF(RowNumber(Nothing) MOD 2=0,”LightGrey”, “White”)

=======================================================================================================

=IIF(IsNothing(Timespan.FromTicks(sum(Fields!Queue_Wait_Time.Value) / Count(Fields!Calls.Value))), Nothing, Code.FormatTimeSpan(Timespan.FromTicks(sum(Fields!Queue_Wait_Time.Value) / Count(Fields!Calls.Value))))

, IIF( WeekdayName(DateInterval.WeekDay,Today) = "Saturday", DateAdd("d",-1,Today() )
SSRS

=IIF(DATEPART(DateInterval.Weekday,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today()))

=IIF(Day(Today)<>1,Today.AddDays(1-Today.Day), IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today())) )

MONTH:  
1) =IIF (
	IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) = Month(Today()), Today.AddDays(1-Today.Day)
	,IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) <> Month(Today()), dateadd("m",-1,dateserial(year(Today),month(Today),1)) 
	, dateadd("m",0,dateserial(year(Today),month(Today),1)) )) = Today.AddDays(1-Today.Day) 
	, dateadd("m",-1,dateserial(year(Today),month(Today),1))
	,IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) = Month(Today()), Today.AddDays(1-Today.Day)
	,IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) <> Month(Today()), dateadd("m",-1,dateserial(year(Today),month(Today),1)) 
	, dateadd("m",0,dateserial(year(Today),month(Today),1)) ))
	)
-- previous
1) start date =>   	=IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) = Month(Today()), Today.AddDays(1-Today.Day)
,IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) <> Month(Today()), dateadd("m",-1,dateserial(year(Today),month(Today),1)) 
, dateadd("m",0,dateserial(year(Today),month(Today),1)) ))

1) start date =>   	=IIF(Day(Today)<>1,Today.AddDays(1-Today.Day), IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today())) )
1) start date =>   	=Today.AddDays(1-Today.Day)  -- first of the month
1) start date => 	=IIF(DATEPART(DateInterval.WeekDay,Today.AddDays(1-Today.Day)) = 7, DateAdd("d",2,Today.AddDays(1-Today.Day))
				,IIF(DATEPART(DateInterval.WeekDay,Today.AddDays(1-Today.Day)) = 1, DateAdd("d",1,Today.AddDays(1-Today.Day))
				,Today.AddDays(1-Today.Day)))

2) end date =>   	=Today ()
2) =IIF (
	IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) = Month(Today()), Today.AddDays(1-Today.Day)
	,IIF(DATEPART(DateInterval.WeekDay,Today) = 2 AND Month(DateAdd("d",-3,Today())) <> Month(Today()), dateadd("m",-1,dateserial(year(Today),month(Today),1)) 
	, dateadd("m",0,dateserial(year(Today),month(Today),1)) )) = Today.AddDays(1-Today.Day) 
	, dateadd("d",-1, dateadd("m",0,dateserial(year(Today),month(Today),1)))
	,IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today()))
	)
-- Previous
2) end date =>		=IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today()))

last day of last month => 	=dateadd("m",0,dateserial(year(Today),month(Today),0))

FirstDayOfPriorMonth = dateadd(month,-1,FirstDayOfMonth)
LastDayOfPriorMonth = EOMONTH(dateadd(month,-1,Date))
=======================================================================================================

  
T-SQL
1st day of last month  =>  DATEADD(month, DATEDIFF(month, 0, GETDATE())-1, 0)
1st day of this month  => DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) 
1st day of next month => DATEADD(month, DATEDIFF(month, 0, GETDATE())1, 0)

 15th of month 	=>	declare @localEndDate date = convert(date,dateadd(d,15 - datepart(d,getdate()),getdate()))
 15th of prev month 	=>	declare @localEndDatePrev date = convert(date, dateadd(month,-1,@localEndDate))
print @localEndDate
print @localEndDatePrev

year-month = CONCAT(datepart (yy,@localEndDate),datepart(mm,@localEndDate))

  IF  ( DATENAME(weekday,getDATE()) = 'Monday' ) BEGIN SET @dlqdate = CAST(GETDATE()-3 as date) END
  IF  ( DATENAME(weekday,getDATE()) = 'Sunday' ) BEGIN SET @dlqdate = CAST(GETDATE()-2 as date) END
  IF  ( DATENAME(weekday,getDATE()) IN ('Tuesday','Wednesday','Thursday','Friday','Saturday')) BEGIN SET @dlqdate = CAST(GETDATE()-1 as date) END
=======================================================================================================

-- gets the 16th of the month beginning with inception month (Aug 2015) thru present month for SSRS dropdown menu selector
SELECT [Date], sortDate = convert(varchar(10),[Date],101)
      FROM [BDE_Data].[dbo].[DateDimension]
	  WHERE [Day] = 16
       and  [Date] > '7/16/2015'
	   and [Date] < 	 EOMONTH ( getDate(), -1 )
	   order by [sortDate] desc

=======================================================================================================

SELECT DISTINCT [Month]
			, [MonthName]
			, [Year]
			, [MMYYYY]
			, [MonthYear]
			, [FirstDayOfMonth]
			, [LastDayOfMonth]
			, [FirstDayOfYear]
			, [LastDayOfYear]
			, [FirstDayOfNextYear] 
			, [FirstDayOfNextMonth]
			, [NextQuarterStart]	= DATEADD(QUARTER, DATEDIFF(QUARTER, 0, FirstDayOfQuarter) + 1, 0) 
			, [NextQuarterEnd]		= DATEADD(QUARTER, DATEDIFF(QUARTER, 0, LastDayOfQuarter) + 2, -1) 
			, [EndOfNextSixMonths]	= DATEADD(MONTH, DATEDIFF(MONTH, 0, [DATE]) + 6, DAY([DATE])-1) 
		 INTO #DateDimension
		 FROM DateDimension
		WHERE [Year] = year(@localEndDate) And [Date] <= @localEndDate


=======================================================================================================

-- calculate elapsed time and display as hh.m

[Total Log In Time] = round ( CONCAT((DATEDIFF(Minute,min([Login Time]),max([Logout Time])) / 60 ),   '.',   (DATEDIFF(Minute,min([Login Time]),max([Logout Time])) % 60 )) ,1)


-- sum SSRS detail rows into subtotal row

=CStr(sum(CInt(split(Fields!Total_Productive_Time.Value,":")(0)))+sum(CInt(split(Fields!Total_Productive_Time.Value,":")(1)))\60)+":"+CStr(sum(CInt(split(Fields!Total_Productive_Time.Value,":")(1))) mod 60+sum(CInt(split(Fields!Total_Productive_Time.Value,":")(2)))\60)  +":"+CStr(sum(CInt(split(Fields!Total_Productive_Time.Value,":")(2))) mod 60)

=======================================================================================================

-- calculate difference between 2 timestamps in these time slices

select  (DATEDIFF(SECOND, min([Login Time]),max([Logout Time])) / 86400) AS Day
,(DATEDIFF(SECOND, min([Login Time]),max([Logout Time])) / 3600) % 24 AS Hour
, (DATEDIFF(SECOND, min([Login Time]),max([Logout Time])) / 60) % 60 AS Min
,  DATEDIFF(SECOND, min([Login Time]),max([Logout Time])) % 60 AS Sec
,  DATEDIFF(SECOND, min([Login Time]),max([Logout Time])) as TotalSec

=======================================================================================================

[Total Log In Time]= CASE  WHEN min([Login Time]) IS NULL  THEN CONVERT(time, DATEADD(ms, isnull(sum(0) ,0) * 1000, 0), 114)
WHEN max([Logout Time]) IS NULL THEN CONVERT(time, DATEADD(ms, isnull(sum(0) ,0) * 1000, 0), 114)
ELSE CONVERT(time,DATEADD(ms,  DATEDIFF(SECOND, min([Login Time]),max([Logout Time]))    * 1000, 0), 114)

=======================================================================================================
-- Left trim leading zeros  (if hours = 00 then retain otherwise strip leading zeros)

Public Function LTrimZeros(varNumber)
Dim strChr As String
Dim n As Integer

strChr = "0"
n = 0

Do Until strChr <> "0"
n = n + 1
LTrimZeros = Mid(varNumber, n)
strChr = Mid(varNumber, n, 1)
Loop
End Function

=IIF(SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(0)),"table1_Agent_Name") = 0 
,
 Right("00"+(SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(0)),"table1_Agent_Name")  

+ (SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(1)),"table1_Agent_Name")  

+ Sum(Cint(split(Fields!Total_Log_In_Time.Value,":").GetValue(2)),"table1_Agent_Name") \60)\60 ).ToString,2) 
+ ":" 
+ Right("00"+((SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(1)),"table1_Agent_Name")  

+ Sum(Cint(split(Fields!Total_Log_In_Time.Value,":").GetValue(2)),"table1_Agent_Name") \60) Mod 60).ToString,2) 
+ ":" 
+ Right("00"+(Sum(Cint(split(Fields!Total_Log_In_Time.Value,":").GetValue(2)),"table1_Agent_Name")  Mod 60).ToString,2)

, 
Code.LTrimZeros(Right("000"+(SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(0)),"table1_Agent_Name") 

+ (SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(1)),"table1_Agent_Name") 

+ Sum(Cint(split(Fields!Total_Log_In_Time.Value,":").GetValue(2)),"table1_Agent_Name")\60)\60 ).ToString,6) 
+ ":" )
+ Right("00"+((SUM(Cint(Split(Fields!Total_Log_In_Time.Value,":").GetValue(1)),"table1_Agent_Name") 

+ Sum(Cint(split(Fields!Total_Log_In_Time.Value,":").GetValue(2)),"table1_Agent_Name")\60) Mod 60).ToString,2) 
+ ":" 
+ Right("00"+(Sum(Cint(split(Fields!Total_Log_In_Time.Value,":").GetValue(2)),"table1_Agent_Name") Mod 60).ToString,2)
)



#,0;(#,0)

--WHERE cast([next payment due date] as date) < DATEADD(month, DATEDIFF(month, 0, @rptdate), 0)	-- this line omits prepaid and pre-30


=Iif(Fields!AckPassMTD.Value = 0, Nothing, "CFPB_Letters_Compliance_DT")  -- drill through



-- retrieve rows for previous quarter through present
      AND ltr_dt BETWEEN dateadd(quarter, datediff(quarter, 0, convert(date,@localEnddate)) - 1, 0) AND convert(date,@localEnddate) 
			and convert(date,@localEnddate)
-- Quarter to Date
			WHERE convert(date,LetterDate) BETWEEN dateadd(quarter, datediff(quarter, 0, convert(date,@localStartDate)) - 0, 0)  -- current quarter begin date
			and convert(date,@localEnddate)

-- Previous Quarter 
			WHERE convert(date,LetterDate) BETWEEN dateadd(quarter, datediff(quarter, 0, convert(date,@localEnddate)) - 1, 0)  -- previous quarter begin date
			and dateadd(quarter, datediff(quarter, -1, convert(date,@localEnddate)) - 1, -1) -- previous quarter end date 

-- mtd
=Today.AddDays(1-Today.Day)
SELECT DATEADD(MONTH, DATEDIFF(MONTH, '19000101', GETDATE()), '19000101')
WHERE convert(date,LetterDate) BETWEEN @localStartDate and @localEnddate

=IIF(Day(Today) = 1, DateValue(Today).AddMonths(-1), IIF(Day(Today) = 15,DateValue(Today).AddDays(-14),Today))

=======================================================================================================

SELECT DISTINCT Month, MonthName, Year, MMYYYY, MonthYear, FirstDayOfMonth, LastDayOfMonth, FirstDayOfYear, LastDayOfYear, FirstDayOfNextMonth, FirstDayOfNextYear
FROM     DateDimension
WHERE  (Date BETWEEN @startDate AND @EndDate)
ORDER BY MMYYYY

[YYYYMM] = convert(int,concat(Convert(char(4),f.[Year]),CASE WHEN Len(Month(f.[Date]))= 1 THEN Concat(convert(char(1),'0'), convert(char(1),Month(f.[Date]))) ELSE convert(char(2),Month(f.[Date])) END))


=======================================================================================================
[RANK] = rank() over(partition by o.ln_no, otd_dt  order by o.sid desc, CAST(otd_dt as date))

filter out the deleted's 
select * into #otd from otd where ( rank = 1 and delta_file_byte <> 'd')  


=======================================================================================================
I typed up Scott’s procedure for the Loan Detail  drill-through. (Thanks Scott!)
Susan


DataSet
---------
1. Create a new embedded dataset named ds_URL

2. Query Type is Text

3. Add this query:   SELECT dbo.ufnGetgetloanlink() AS URL

4. Field name is URL



Parameter
-----------
1. Create a hidden Parameter named URL

2. set the Default Values to "Get values from a query"

3. Dataset:  ds_URL

4. Value Field:  URL



Report field
---------------
1. Find the Loan_Number column

2. Click on Text Box Properties

3. Click on Action, Select URL

4. Set this expression for the Hyperlink

="javascript:void(window.open('"+ Parameters!URL.Value & Fields!Loan_Number.Value + "','_blank'))"


=======================================================================================================
** NEW client code **

DECLARE	 @localEndDate date = @enddate
			,@localStartDate date = @startDate
			,@localClientCode varchar(MAX) = @Client_Code

	select [Loan Number] = l.ln_no, l.iv_id, l.iv_cat_cd, iv_nm = ic.investor
	INTO #ClientLoans
 	FROM BDE_Data.dbo.ufnGetMax_loan(@localEndDate) l
	INNER JOIN BDE_Data.dbo.investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 


=IIF(Parameters!Client_Code.Count=CountRows("ListClients"),"All",IIF(Parameters!Client_Code.Count = 1 , Parameters!Client_Code.Label(0), JOIN( Parameters!Client_Code.Label,", ")))

	-- if called by batch export file get all
	select @localClientCode =  coalesce(@localClientCode+',','') + client from (select distinct client from investor_client) t
	-- if called by SSRS report retrieve parms selected by the user								
	select @localClientCode = CASE WHEN @Client_Code IS NOT NULL THEN @Client_Code ELSE @localClientCode END


	
=======================================================================================================



Declare @StartDt date = '2016-06-01'


Declare @EndDt date = @localEndDate


declare @Days int = DATEDIFF(d, @StartDt, @EndDt) 



SELECT @StartDt, @EndDt, @Days



Declare @i int = 0



WHILE @i < @Days
	

begin

	

INSERT INTO #xfers (Loan_date, Xfers) 
	
SELECT DATEADD(d, @i, @StartDt), Xfers
	
FROM the_other_table
	
	
SET @i = @i + 1
	
	

END


=======================================================================================================


DECLARE @localEndDate as datetime = '7/7/2016', @localState varchar(200) = 'all'
                                                  	
	SELECT DISTINCT c.[LOAN NUMBER]
	FROM [BDESime].[dbo].[ListLoansForClient]('TMS000') c
	JOIN  dbo.property p on c.[LOAN NUMBER] = p.[ln_no]
	WHERE p.[pr_alpha_state_cd] LIKE (CASE @localState WHEN 'ALL' THEN '%' ELSE @localState  END)




SELECT        'ALL' AS pr_alpha_state_cd, 1 AS Sid
UNION
SELECT DISTINCT pr_alpha_state_cd, 2 AS sid
FROM            property
WHERE        (pr_alpha_state_cd IS NOT NULL)
ORDER BY sid, pr_alpha_state_cd


=======================================================================================================
-- COLLATION
SELECT  r.[ReportName]
		, r.[UserName]
		, r.[Date]
		, r.[Count]
		, r.TimeDataRetrievalSum
		, r.TimeProcessingSum 
		, r.TimeRenderingSum 
		, r.ByteCountSum 
		, r.RowCountSum 
		, [UserNameLabel] = right(r.username, charindex('\', REVERSE(r.username) +'\' ) -1) 
	FROM Reports r
	LEFT join #users u
	-- fix for server error due to the SSRS report server having a different collation than the OLTP database servers
	ON u.UserName COLLATE DATABASE_DEFAULT = r.UserName COLLATE DATABASE_DEFAULT	
	ORDER BY r.[Date], r.[ReportName], r.[UserName], r.[Count] 
 

====================================================================================================================
convert to seconds:
	 	, [Speed of Answer] = AVG(DATEDIFF(SECOND, '00:00:00',f.[Speed of Answer]))  -- convert to seconds
		, [TALK TIME] = AVG(DATEDIFF(SECOND, '00:00:00',f.[Talk Time])) -- convert to seconds
		--,speed2 =  datepart(hh,f.[Speed of Answer])*3600 + datepart(mi,f.[Speed of Answer]) * 60 + datepart(ss,f.[Speed of Answer])
		--, talk2 = datepart(hh,f.[TALK TIME])*3600 + datepart(mi,f.[TALK TIME]) * 60 + datepart(ss,f.[TALK TIME])


====================================================================================================================
	DECLARE  @rptdate date = CAST(GETDATE() as date) 
			,@dlqdate date 
	   
	   IF  ( DATENAME(weekday,getDATE()) = 'Monday' ) BEGIN SET @dlqdate = CAST(GETDATE()-3 as date) END
	   IF  ( DATENAME(weekday,getDATE()) = 'Sunday' ) BEGIN SET @dlqdate = CAST(GETDATE()-2 as date) END
	   IF  ( DATENAME(weekday,getDATE()) IN ('Tuesday','Wednesday','Thursday','Friday','Saturday')) BEGIN SET @dlqdate = CAST(GETDATE()-1 as date) END

	   IF  ( DATENAME(weekday,getDATE()) = 'Monday' ) BEGIN SET @rptdate = CAST(GETDATE()-3 as date) END
	   IF  ( DATENAME(weekday,getDATE()) = 'Sunday' ) BEGIN SET @rptdate = CAST(GETDATE()-2 as date) END
	   IF  ( DATENAME(weekday,getDATE()) IN ('Tuesday','Wednesday','Thursday','Friday','Saturday')) BEGIN SET @rptdate = CAST(GETDATE()-1 as date) END


if object_id('tempdb..#t1') is not null drop table #t1

-- regex to exclude 
CASE WHEN @local_includeREO = 0 THEN '[^reo]%' ELSE '%' END

====================================================================================================================
 Client code - using delinquency_snapshot table
====================================================================================================================

	SELECT DISTINCT d.[Loan Number]
				,d.[Loan Date]
				,[Mth Status Name] = CASE WHEN d.[Proper_Status] like '%REO%' THEN 'REO' ELSE d.[Mth Status Name] END
				,d.[Proper_Status] 
				,d.[First Principal Balance]
			INTO #Delinquency
			FROM [BDESIME].[dbo].[delinquency_snapshot] d (nolock)
			INNER JOIN bde_data.dbo.investor_client ic ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
			 AND ic.client IN (SELECT b.item FROM BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b)
		 WHERE d.[loan date] IN (@PreviousPriorDate, @localPriorDate, @localCurrentDate)
		 and d.[MTH STATUS NAME] in ('Pre-30 Days Delinquent','Prepaid or Current','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','120+ Days Delinquent')
		 AND d.[First Principal Balance] > 0 

====================================================================================================================
SELECT BOM = CASE WHEN getdate() >  BOM THEN DateAdd(month,-1,BOM) ELSE BOM END
, EOM = CASE WHEN getdate() >  BOM THEN DateAdd(month,-1,EOM) ELSE EOM END
, MonthYear = CASE WHEN getdate() >  BOM THEN concat(DateName(month,(dateadd(month,-1,BOM))),' ',DateName(year,(dateadd(month,-1,BOM)))) ELSE MonthYear END
--, MonthYear = CASE WHEN getdate() >  BOM THEN Concat(DatePart(month,dateadd(MonthName,-1,BOM)),' ',DatePart(year,dateadd(year,-1,BOM))) ELSE MonthYear END
, sid
FROM     SSRSmonthYear
WHERE  (EOM >= '8/1/2015') AND (EOM <= GETDATE()) OR
                  (EOM >= '8/1/2015') AND (BOM <= GETDATE())
ORDER BY sid DESC
====================================================================================================================
REPLACE everything to left of symbol
	, DLQStatusFrom = LEFT([Movement], CHARINDEX('_', [Movement]) - 1) 
REPLACE everything to right of string
	    , DLQStatusTo = REPLACE(SUBSTRING([Movement], CHARINDEX('_', [Movement]), LEN([Movement])), '_To_', '') 
====================================================================================================================
select * from five9_activity where [DISPOSITION] = 'Abandon' and [ABANDONED]=1 and [TIME TO ABANDON] < 00:00:05'
====================================================================================================================

/***********************************************************/
		  -- insert duplicate first of month process days
		  DECLARE @Dupe int = @CurrMthTotProcessCalendarDays - @PriorMthTotProcessCalendarDays
		  -- There are more days in Current Month than Prior Month
		 IF @Dupe > 0
		  BEGIN 
		  Declare @i int = 0
		 	WHILE @i < @Dupe -1
				BEGIN
				  INSERT INTO #cashDash
				  SELECT Distinct * 
				  FROM #cashdash 
				  WHERE convert(date,[Process Date]) = @PriorMonth
				 SET @i = @i+1
				END
			
		 END

		  -- There are more days in Prior Month than Currnet Month
		  IF @Dupe < 0
		  BEGIN 
		  Declare @j int = 0
			WHILE @j < abs(@Dupe) -1
				BEGIN
				  INSERT INTO #cashdash
				  SELECT Distinct * 
				  FROM #cashdash 
				  WHERE convert(date,[Process Date]) = @StartOfMonth
				 SET @j = @j+1
				END
		 END

====================================================================================================================
declare @yyyymm int = 201601
print  CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END


UPDATE DateDimension
set NbrProcessDaysPriorMth = d2.NbrProcessDaysPriorMth
FROM DateDimension d
JOIN (
SELECT distinct C_YYYYMM = c.YYYYMM, c.NbrProcessDays, NbrProcessDaysPriorMth =p.NbrProcessDays, P_YYYYMM = p.YYYYMM
FROM      (-- Get records from the Current month from the OriginalFact table.
     SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth 
      FROM  DateDimension
      WHERE  yyyymm IN (@yyyymm)
      ) c -- Current
   CROSS APPLY (-- Get records from the Prior month.
     SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth 
      FROM  DateDimension
      WHERE  yyyymm = convert(int,CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END)
      ) p -- Prior
   group by C.YYYYMM, c.NbrProcessDays,p.YYYYMM,p.NbrProcessDays
   ) d2
   ON d.YYYYMM = d2.C_YYYYMM

SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth  from DateDimension where YYYYMM = @yyyymm
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
====================================================================================================================
