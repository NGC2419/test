=======================================================================================================

-- renders the previous Business process day

Declare @StartDate date = '7/4/2017'
Declare @localStartDate date = (SELECT max([ProcessDate]) from dbo.DateDimension (nolock) WHERE convert(date,[Date]) < @StartDate AND [ProcessDate] IS NOT NULL)

=======================================================================================================


select dateadd(quarter, datediff(quarter, 0, getdate()) - 0, 0)  -- current quarter begin date
		,dateadd(quarter, datediff(quarter, 0, getdate()) - 1, 0)  -- previous quarter begin date
       ,dateadd(quarter, datediff(quarter, 0, getdate()) - 2, 0)
       ,dateadd(quarter, datediff(quarter, 0, getdate()) - 3, 0);

select dateadd(quarter, datediff(quarter, -1, getdate()) - 0, -1)  -- current quarter end date
       ,dateadd(quarter, datediff(quarter, -1, getdate()) - 1, -1) -- previous quarter end date
       ,dateadd(quarter, datediff(quarter, -1, getdate()) - 2, -1)
       ,dateadd(quarter, datediff(quarter, -1, getdate()) - 3, -1);

-- =========================================================================================

SELECT DATEADD(month, DATEDIFF(month, 0, @mydate), 0) AS StartOfMonth

use BDE_Data
go

--alter procedure getDateRange AS
SELECT BOM
		,EOM      
       ,DateName (dw, EOM) as weekday    
       ,DatePart (wk, EOM) as Week_Number_Of_Year       
       ,datename(mm, EOM) as MonthName
	   , month(EOM) As month      
       ,YEAR (EOM) as Year    
        ,Row_Number() OVER (ORDER BY EOM) As id   
       , CASE    
        WHEN DateName (dw, EOM)  = 'Monday' THEN 1   
        WHEN DateName (dw, EOM)  = 'Tuesday' THEN 2   
        WHEN DateName (dw, EOM)  = 'Wednesday' THEN 3   
        WHEN DateName (dw, EOM)  = 'Thursday' THEN 4   
        WHEN DateName (dw, EOM)  = 'Friday' THEN 5   
        WHEN DateName (dw, EOM)  = 'Saturday' THEN 6   
        ELSE 0 END As WeekDayNumber     
	--INTO SSRSmonthYear
	FROM   dbo.SSRSmonthYear
WHERE EOM >= '8/1/2015' and EOM   <= GETDATE()
ORDER BY SID DESC

-- ,Row_Number() OVER (ORDER BY the_date) As id   
-- drop table SSRSmonthYear

/*
=======================================================================================================
-- Gets BOM, EOM, [MonthName Year], SID

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

=======================================================================================================


--update smonthyear 
--set EOM = convert(date,concat(case when month in (1,2,3,4,5,6,7,8,9) THEN concat('0',month) else month end,'/', daysinmonth,'/', year) ) from SSRSmonthYear


-- select EOM = convert(date,concat(case when month in (1,2,3,4,5,6,7,8,9) THEN concat('0',month) else month end,'/', daysinmonth,'/', year) ) from SSRSmonthYear


=======================================================================================================

=IIF(IsNothing(Timespan.FromTicks(sum(Fields!Queue_Wait_Time.Value) / Count(Fields!Calls.Value))), Nothing, Code.FormatTimeSpan(Timespan.FromTicks(sum(Fields!Queue_Wait_Time.Value) / Count(Fields!Calls.Value))))


SSRS

=IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today()))


  
T-SQL

  IF  ( DATENAME(weekday,getDATE()) = 'Monday' ) BEGIN SET @dlqdate = CAST(GETDATE()-3 as date) END
  IF  ( DATENAME(weekday,getDATE()) = 'Sunday' ) BEGIN SET @dlqdate = CAST(GETDATE()-2 as date) END
  IF  ( DATENAME(weekday,getDATE()) IN ('Tuesday','Wednesday','Thursday','Friday','Saturday')) BEGIN SET @dlqdate = CAST(GETDATE()-1 as date) END


#,0;(#,0)


MONTH:  
1) start date =>   	=Today.AddDays(1-Today.Day)  -- first of the month
2) end date =>   	=Today ()



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


=======================================================================================================
=IIF(Parameters!Client_Code.Count = 1 , Parameters!Client_Code.Label(0), JOIN( Parameters!Client_Code.Label,", "))

=IIF(Parameters!Client_Code.Count=CountRows("ListClients"),"All"
,IIF(Parameters!Client_Code.Value(0) = "TMS000","The Money Source"
,IIF(Parameters!Client_Code.Value(0) = "EVB001","Everbank"
," "
)
)
)

=IIF(Parameters!Client_Code.Count = 1 , Parameters!Client_Code.Value(0), JOIN(Parameters!Client_Code.Value,", "))




=======================================================================================================
[RANK] = rank() over(partition by o.ln_no, otd_dt  order by o.sid desc, CAST(otd_dt as date))

--filter out the deleted 
select * into #otd from otd where ( rank = 1 and delta_file_byte <> 'd')  


=======================================================================================================


DataSet
---------
1. Create a new embedded dataset named ds_URL

2. Query Type is Text

3. Add this query:   SELECT   dbo.ufnGetgetloanlink() AS URL

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


CREATE TABLE #ClientLoans 
       ([LOAN NUMBER] VARCHAR(13)
       ,ClientSelected varchar(50)
       ,Client_Code varchar(50)
       ,Client_Name varchar(400)
       ,Loan_Date date
       ,Effective_Date date
       ,End_Date date
       ) 
                                                      
       INSERT INTO #ClientLoans ([LOAN NUMBER], ClientSelected, [Client_Code], Client_Name, Loan_Date, Effective_Date, End_Date)
       SELECT DISTINCT c.[LOAN NUMBER], @Client_Code, c.[Client], cd.Client_Name, c.Loan_Date, cd.Effective_Date, cd.End_Date
       FROM [BDE_Data].[dbo].[ListLoansByClient](@Client_Code,@localEndDate) c
       LEFT JOIN BDESIME.sime.Clients cd on c.Client = cd.Client_code
	   WHERE c.loan_date BETWEEN cd.Effective_Date and cd.End_Date
         AND c.loan_date <= @localEndDate


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



