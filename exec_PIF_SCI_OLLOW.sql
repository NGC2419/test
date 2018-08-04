use bde_data
go

-- SCI PIF COUNT 
exec dbo.sp_sci_pif_rpt '11/10/2017',NULL   -- 31 rows
go
-- MATCHES SCI PIF COUNT 
exec [dbo].[sp_PIF_OLLW_v2_AllHazAndAllTaxPayees] NULL, '11/10/2017','11/10/2017'   -- 47 rows  (31 distinct loan numbers)
go
-- MATCHES SCI PIF COUNT 
exec [sp_PIF_OLLW_V1_allHazPayees] NULL, '11/10/2017','11/10/2017'   -- 34 rows  (31 distinct loan numbers)
go
