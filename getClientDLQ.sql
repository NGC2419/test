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