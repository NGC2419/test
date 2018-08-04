USE [BDE_Data]
GO

-- Month
DECLARE @local_enddate date = '2/28/2017'
	declare @local_investor  nvarchar(10)  = 'FNMA'

    SELECT l.[LOAN NUMBER] as ln_no   
    ,l2.ln_1st_prin_ba    
    ,CAST([PAYMENT IN FULL DATE] as date) as ln_pif_dt  
    FROM [BDESime].dbo.[loan]  l  
      INNER JOIN investor_client ic on ic.inv_id = l.[INVESTOR ID] and ic.inv_cat = l.[CATEGORY CODE]  
      AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit('TMS000', ',') b)   
     INNER JOIN [dbo].[ufnGetMax_loan_POamt](@local_enddate)  l2 on  l2.ln_no = l.[LOAN NUMBER]       
      WHERE CAST(l.[PAYMENT IN FULL DATE] as date) Between DATEADD(mm, DATEDIFF(mm, 0, @local_enddate), 0)  and   @local_enddate  
      and ic.investor like  @local_investor   

-- Day
DECLARE @local_enddate date = '2/21/2017'
	--declare @local_investor  nvarchar(10)  = 'FNMA'

    SELECT l.[LOAN NUMBER] as ln_no   
    ,l2.ln_1st_prin_ba    
    ,CAST([PAYMENT IN FULL DATE] as date) as ln_pif_dt  
	FROM [BDEsime].dbo.[loan]  l  
      INNER JOIN investor_client ic on ic.inv_id = l.[INVESTOR ID] and ic.inv_cat = l.[CATEGORY CODE]  
      AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit('TMS000', ',') b)   
     INNER JOIN [dbo].[ufnGetMax_loan_POamt](@local_enddate)  l2 on  l2.ln_no = l.[LOAN NUMBER]       
      WHERE CAST(l.[PAYMENT IN FULL DATE] as date) = @local_enddate
      -- and ic.investor like  @local_investor   

/*	
SELECT * FROM [dbo].[Portfolio_Summary_Investor] 
where loandate = '2/28/2017'
and client = 'tms000' 
order by loandate

SELECT * FROM [dbo].[Portfolio_Summary] 
where convert(date, loandate) between '2/1/2017' AND '2/28/2017'
and client = 'tms000' 
order by loandate

*/

/*
UPDATE [Portfolio_Summary] 
SET Payoffs = 192
WHERE Payoffs = 193
and client = 'tms000' AND loandate = '2/1/2017'

UPDATE [Portfolio_Summary] 
SET Payoffs = 83
WHERE Payoffs = 84
and client = 'tms000' AND loandate = '2/21/2017'
*/

/* Investors
FHLMC	
FNMA	
GNMA	
TMS	
SFLS
*/	