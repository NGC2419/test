USE [BDE_Data]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--CREATE PROCEDURE [dbo].[sp_Timeline_Matrix_Aging]
--    (
--	@startDate date,
--	@enddate date,
--	@Client_Code VARCHAR(MAX) = NULL
--	) 
--AS
-- =======================================================
-- Author:		S. Delaney
-- Create date: 20161212
-- Description:	Timeline Matrix Aging Report
-- =======================================================
-- exec sp_Timeline_Matrix_Aging '11/28/2016','11/30/2016','tms000,evb001'
-- select * FROM BDE_Data.dbo.ufnGetMax_loan('11/30/2016') where ln_no = '0003015914'
 DECLARE @startDate date = '11/28/2016', @enddate date = '11/30/2016', @Client_Code VARCHAR(MAX) = 'tms000,evb001'
	SET NOCOUNT ON;

	DECLARE @localStartDate date = @startDate
	,@localEnddate date = @enddate
	,@localClientCode varchar(MAX) = @Client_Code

		select [loan number] = l.ln_no
			, l.iv_id
			, l.iv_cat_cd
			, ic.investor
			, UPB = l.ln_1st_prin_ba
			, l.ln_sale_dt
			, l.ln_fc_wkst_stat_cd
			, l.ln_bkr_status_cd
			, l.ln_lm_status_cd
			, l.load_date
			, LoanType = CASE WHEN l.ln_lo_ty IN (1,5) THEN 'HUD_FHA' ELSE 'FNMA_Other' END 
	INTO #ClientLoans
 	FROM BDE_Data.dbo.ufnGetMax_loan(@localEndDate) l
	INNER JOIN BDE_Data.dbo.investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 
	LEFT JOIN [bdesime].[dbo].[investor_category] i WITH(NOLOCK)  ON i.[INVESTOR ID]=l.[iv_id] AND i.[Category Code] = l.iv_cat_cd 

	;WITH FC AS (
	SELECT l.[loan number]
		, l.loanType
		, f.fc_start_dt
		, f.fc_sale_dt
		, f.fc_setup_dt
		, f.fc_full_sttl_dt
		, l.UPB
		-- borrower
		, [Borrower Name] = CONCAT(b.[MORTGAGOR FIRST NAME],' ',b.[MORTGAGOR LAST NAME])
		-- property
		, p.[property street address]
		, p.[city name]		
		, [State] = p.[PROPERTY ALPHA STATE CODE]
		-- status codes
		, [foreclosure status code] = f.fc_status_cd
		, [Foreclosure Status Desc] = f.fc_status_code_de
		-- Original owner occupied or non-owner occupied
		, [occupancy current status code] 
		 --p.pr_occ_status_cd
		, [occupancy description] = case when p.[OCCUPANCY CODE] = 1 then 'Owner Occupancy'
										 when p.[OCCUPANCY CODE] = 2 then 'Owner Does Not Occupy'
										 when p.[OCCUPANCY CODE] = 3 then 'Investment Property'
										 ELSE p.[OCCUPANCY CODE] 
									end
		,[ln foreclosure status code] = l.ln_fc_wkst_stat_cd
		,[bankruptcy status code] = l.ln_bkr_status_cd
		,[loss mit status code] = l.ln_lm_status_cd
		,[Days to Complete Sale] = isnull(convert(int, datediff(day, cast(fc_start_dt as date), fc_sale_dt) ),0)
		,[HUD_FC_TimeInDays] = convert(int,CASE 
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AK' THEN 300
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AL' THEN 180
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AR' THEN 330
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AZ' THEN 180
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'CA' THEN 330
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'CO' THEN 360
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'CT' THEN 630
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'DC' THEN 210
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'DE' THEN 780
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'FL' THEN 750
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'GA' THEN 180
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'HI' THEN 900
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'IA' THEN 510
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'ID' THEN 390
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'IL' THEN 510
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'IN' THEN 390
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'KS' THEN 300
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'KY' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'LA' THEN 360
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MA' THEN 290
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MD' THEN 540
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'ME' THEN 810
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MI' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MN' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MO' THEN 150
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MS' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MT' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NC' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'ND' THEN 450
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NE' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NH' THEN 330
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NJ' THEN 570
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NM' THEN 750
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NV' THEN 720
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NY' THEN 630
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'OH' THEN 390
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'OK' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'OR' THEN 900
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'PA' THEN 630
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'PR' THEN 630
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'RI' THEN 660
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'SC' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'SD' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'TN' THEN 180
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'TX' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'UT' THEN 360
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'VA' THEN 210
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'VT' THEN 720
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WA' THEN 540
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WI' THEN 360
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WV' THEN 210
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WY' THEN 210
		END)
		,[FNMA_FC_TimeInDays] = convert(int,CASE 
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AK' THEN 360
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AL' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AR' THEN 390
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'AZ' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'CA' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'CO' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'CT' THEN 690
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'DC' THEN 180
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'DE' THEN 840
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'FL' THEN 810
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'GA' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'HI' THEN 960
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'IA' THEN 510
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'ID' THEN 450
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'IL' THEN 570
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'IN' THEN 450
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'KS' THEN 360
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'KY' THEN 480
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'LA' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MA' THEN 320
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MD' THEN 600
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'ME' THEN 870
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MI' THEN 210
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MN' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MO' THEN 210
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MS' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'MT' THEN 330
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NC' THEN 330
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'ND' THEN 510
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NE' THEN 300
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NH' THEN 390
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NJ' THEN 630
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NM' THEN 810
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NV' THEN 730
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'NY' THEN 700
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'OH' THEN 450
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'OK' THEN 480
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'OR' THEN 960
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'PA' THEN 690
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'PR' THEN 690
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'RI' THEN 720
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'SC' THEN 480
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'SD' THEN 480
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'TN' THEN 240
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'TX' THEN 300
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'UT' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'VA' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'VT' THEN 780
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WA' THEN 600
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WI' THEN 420
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WV' THEN 270
		WHEN p.[PROPERTY ALPHA STATE CODE] = 'WY' THEN 240
		END)
 	FROM #ClientLoans l
	LEFT JOIN [bdesime].[dbo].[borrower] b WITH (NOLOCK)		ON b.[LOAN NUMBER]=l.[loan number]
	LEFT JOIN [bdesime].[dbo].[property] p WITH (NOLOCK)		ON p.[LOAN NUMBER]=l.[loan number]
	LEFT JOIN [bde_data].dbo.ufnGetMax_foreclosure(@localEndDate) f on f.ln_no = l.[loan number]
	where l.load_date between @localStartDate AND @localEndDate 
	-- Foreclosure status must be completed
	AND l.ln_fc_wkst_stat_cd = 'C' -- 'C','A','R','S'
	-- Foreclosure sale date cannot be blank or null
	and isdate(l.ln_sale_dt) = 1
) 

	SELECT DISTINCT *
	-- Use HUD time frames for FHA loans. Use FNMA time frames for all other loans as per Ruth Hernandez.
	,ComplianceVariance =  CASE WHEN LoanType = 'HUD_FHA'    THEN convert(int,[HUD_FC_TimeInDays] - [Days to Complete Sale])
								WHEN LoanType = 'FNMA_Other' THEN  convert(int,[FNMA_FC_TimeInDays] - [Days to Complete Sale])
								ELSE 0 
							END
	,Compliance =  CASE WHEN LoanType = 'HUD_FHA'   AND [Days to Complete Sale] <= [HUD_FC_TimeInDays]  THEN 'Y' 
						WHEN LoanType = 'FNMA_Other' AND [Days to Complete Sale] <= [FNMA_FC_TimeInDays] THEN 'Y'
						ELSE 'N' 
					END
	FROM FC
	order by [loan number]

	DROP TABLE #ClientLoans
