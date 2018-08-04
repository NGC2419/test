
------------------------------------------------------------------------------------------

=IIF(RowNumber(Nothing) MOD 2=0,”Gainsboro”, “White”)

------------------------------------------------------------------------------------------

IF object_id('tempdb.dbo.#dlq')	IS NOT NULL DROP TABLE #dlq

------------------------------------------------------------------------------------------

start date  =IIF(Day(Today)<>1,Today.AddDays(1-Today.Day), IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today())) )

end date    =IIF(DATEPART(DateInterval.WeekDay,Today) = 2, DateAdd("d",-3,Today()) ,DateAdd("d",-1,Today()))

------------------------------------------------------------------------------------------
-- links

NEW
="javascript:openLoan('" +  Fields!Loan_Number.Value + "','_blank')"
="javascript:openLoan('" +  Fields!ln_no.Value + "','_blank')"

OLD
="javascript:void(window.open('"+ Parameters!URL.Value & Fields!Loan_Number.Value + "','_blank'))"

------------------------------------------------------------------------------------------

-- step codes & descriptions
select [tsi step code], [tsi comment log code], [tsi step description] 
from bdesime.dbo.template_step_info (nolock) 
where [tsi step code] in ('F10','432','R77','R38','R39')


SELECT p.spid, p.status, p.hostname, p.loginame, p.cpu, last_batch, t.text FROM master.dbo.sysprocesses as p CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) t order by loginame 

------------------------------------------------------------------------------------------

SELECT DISTINCT [Date] = convert(date,start_time),HostName,ServerName,DatabaseName,ObjectName,LoginName,ApplicationName,[Path]
FROM sys.traces T CROSS Apply sys.fn_trace_gettable(CASE WHEN CHARINDEX('_', T.[path]) <> 0 THEN SUBSTRING(T.PATH, 1, CHARINDEX('_', T.[path]) - 1) + '.trc' ELSE T.[path] End, T.max_files) I 
WHERE (DatabaseName IN ('BDE_Data','BDESime') OR DatabaseName Like 'Borrower%')
--AND [path] = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Log\log_75.trc'

------------------------------------------------------------------------------------------

exec msdb.dbo.sp_help_job

------------------------------------------------------------------------------------------

sp_datadictionary 'loan'

------------------------------------------------------------------------------------------
-- get lo type descriptions

DECLARE @ENDDATE DATE = '8/25/2017', @Client_Code varchar(200) = 'tms000,evb001'

	DECLARE @LocalEndDate Date		= @endDate
	,@localClientCode varchar(max)	= @Client_Code
    ,@LoanCount int 

	Select distinct d.[Loan Number]
					, ic.Client
					, iv_id = d.[INVESTOR ID]
					, d.iv_cat_cd
					, iv_nm = ic.investor
					, d.[MSP DLQ STATUS]
					, [Proper_Status]  = (SELECT bde_data.dbo.ProperCase(d.Proper_Status)) 
					, [Account Status] = d.[mth status name]
					--= , [Proper_Status] = CASE WHEN d.Proper_Status like '%REO%'	THEN 'REO' ELSE (SELECT bde_data.dbo.ProperCase(d.Proper_Status)) END
					, d.[INVESTOR ID],
					d.[LO TYPE],
					[LO TYPE DESCRIPTION] = CONVERT(VARCHAR(50),'  '),
					d.[FIRST PRINCIPAL BALANCE],
					d.[FIRST P AND I AMOUNT],
					d.[NEXT PAYMENT DUE DATE],
					d.[CS BORR ORIG CREDIT QLTY CODE],
					d.[CS BORR CREDIT QUALITY CODE],
					d.[CS BORR CREDIT QUALITY DATE],
					[CATEGORY CODE] = d.iv_cat_cd,
					d.[MAN CODE]
		INTO #ClientLoans
 		FROM [BDESIME].[dbo].[delinquency_snapshot] d (nolock)
		INNER JOIN bde_data.dbo.investor_client ic (nolock) ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
		AND ic.client IN (SELECT b.item FROM BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b)  
		WHERE convert(date,[loan date]) = @localEndDate
		AND d.[first principal balance] > 0 

	--/*   LO TYPE DESCRIPTION    */
		UPDATE #ClientLoans
		SET [LO TYPE DESCRIPTION] = C.CD_FULL_NAME
		FROM #ClientLoans M
		JOIN (
		SELECT DISTINCT  CD 
					   , CD_FULL_NAME
		FROM [BDE_DATA].DBO.[TBL_CODE_TRANSLATION] (nolock)
		GROUP BY CD, CD_FULL_NAME
		) C
		ON M.[LO TYPE] = C.[CD]

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------

---------------------------------------------
