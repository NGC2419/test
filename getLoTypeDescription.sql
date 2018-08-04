USE [BDESime]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER PROCEDURE [dbo].[sp_sd]
--    (@endDate DATETIME, @Client_Code varchar(MAX)) 
--AS
/* 20170828  SD New.  */
-- EXEC sp_sd '8/25/2017','tms000,evb001'
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

	IF object_id('tempdb.dbo.#results')		IS NOT NULL DROP TABLE #results
	IF object_id('tempdb.dbo.#loans')		IS NOT NULL DROP TABLE #LOANS
	IF object_id('tempdb.dbo.#ClientLoans')	IS NOT NULL DROP TABLE #ClientLoans

GO
