DECLARE	 @localEndDate date = @enddate
			,@localStartDate date = @startDate
			,@localClientCode varchar(MAX) = @Client_Code

	select [Loan Number] = l.ln_no, l.iv_id, l.iv_cat_cd, iv_nm = ic.investor, ic.Client_Name
	INTO #ClientLoans
 	FROM bde_data.dbo.ufnGetMax_loan(@localEndDate) l
	INNER JOIN bde_data.dbo.investor_client ic on ic.inv_id = l.iv_id and ic.inv_cat = l.iv_cat_cd
	AND ic.client IN (SELECT b.item from BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b) 
	-- AND ic.client IN (select Distinct Client_Code from BDESIME.sime.Clients) 
----------------------------------------------------------------------------------------------------

USE [BDE_Data]
GO
-- select * from portfolio_summary order by convert(date,loanDate) desc
 	DECLARE @localClientCode varchar(MAX) 
	 select @localClientCode = coalesce(@localClientCode+',','') + client from (select distinct client from investor_client) t

		  Select ic.Client
				,[loan date] = convert(date,d.[loan date])
				,UPB = sum(d.[FIRST PRINCIPAL BALANCE])
		    FROM [BDESIME].[dbo].[delinquency_snapshot] d (nolock)
		    INNER JOIN bde_data.dbo.investor_client ic (nolock) ON ic.inv_id = d.[INVESTOR ID] AND ic.inv_cat = d.iv_cat_cd
					AND ic.client IN (SELECT b.item FROM BDESime.dbo.fnMultiValueSplit(@localClientCode, ',') b)  
  	-- change date for ad-hoc updates
		where convert(date,d.[loan date]) = '3/1/2017' 
			  and  d.[FIRST PRINCIPAL BALANCE] <> 0 
			group by ic.Client,d.[LOAN DATE]


----------------------------------------------------------------------------------------------------





OLD

DECLARE @localStartDate datetime = @startDate
       ,@localEnddate   datetime = @endDate
	   ,@localClientCode varchar(200) = @Client_Code

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
       SELECT DISTINCT c.[LOAN NUMBER], @localClientCode, c.[Client], cd.Client_Name, c.Loan_Date, cd.Effective_Date, cd.End_Date
       FROM [BDE_Data].[dbo].[ListLoansByClient](@localClientCode,@localEndDate) c
       LEFT JOIN BDESIME.sime.Clients cd on c.Client = cd.Client_code
	   WHERE c.loan_date BETWEEN cd.Effective_Date and cd.End_Date
         --AND c.loan_date <= @localEndDate
