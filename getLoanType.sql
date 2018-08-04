/*
SELECT DISTINCT cd_full_name
FROM   bde_data.dbo.tbl_code_translation WITH (nolock)
WHERE  (tbl_column = 'ln_lo_ty')
AND cd_full_name IN ('FHA','VA','Conventional wo/PMI','Conventional w/PMI','USDA/RHS')
*/	
DECLARE @local_date  date = '5/23/2016' 
DECLARE @local_state nvarchar(3) = 'ALL' 
DECLARE @Client_Code varchar(200) = 'tms000'

	-- loan numbers
 	SELECT  d.[LOAN NUMBER],  RTRIM(t3.cd_full_name)  as Loan_Type
		    , [LOAN DATE]
			, [MTH STATUS NAME]  as 'dlq_status' 
			, [SortID] = CASE [MTH STATUS NAME]
				WHEN  'Prepaid or Current'		THEN  1
				WHEN  'Pre-30 Days Delinquent'	THEN  2
				WHEN  '30 Days Delinquent'		THEN  3 
				WHEN  '60 Days Delinquent'		THEN  4
				WHEN  '90 Days Delinquent'		THEN  5
			  ELSE  6  
			END 
		INTO #DLQ
		FROM   [BDESIME].[dbo].[delinquency_snapshot] d 
	       INNER JOIN bde_data.dbo.investor_client ic ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
						AND ic.client IN (SELECT b.item FROM BDESime.dbo.fnMultiValueSplit(@Client_Code, ',') b) 	
		LEFT JOIN [BDESime].[dbo].[property] p on p.[LOAN NUMBER] = d.[LOAN NUMBER]	
	    JOIN  [dbo].tbl_code_translation t3  ON t3.cd = d.[LO TYPE] and t3.cd_group = 2            --Loan Type	
		where [FIRST PRINCIPAL BALANCE] > 0  and p.[PROPERTY ALPHA STATE CODE] like (CASE @local_state WHEN 'ALL' THEN '%' ELSE @local_state END)
		and [LOAN DATE] = @local_date
		option (recompile)  
 
		-- pivot counts
		SELECT  dlq_status,  [Conventional w/PMI], [Conventional wo/PMI],[FHA],[USDA/RHS],[VA], [Conventional w/PMI]+ [Conventional wo/PMI]+[FHA]+[USDA/RHS]+[VA] As 'Grand Total' INTO #pivot
		  FROM #DLQ
		PIVOT
		(
			   COUNT([LOAN NUMBER])
		   FOR [Loan_Type] IN ([Conventional w/PMI], [Conventional wo/PMI],[FHA],[USDA/RHS],[VA])
		) AS P
		Where [LOAN DATE] =  @local_date
		order by SortID

		select * from #pivot
		select top 4 * from #DLQ
		select top 10 * from Portfolio_Summary

		drop table  #DLQ
		drop table  #pivot

		GO
