-- This script adds computed columns for delinquency percentages

alter table Portfolio_Summary
 drop column pct_prepaid
alter table Portfolio_Summary
 drop column pct_current
alter table Portfolio_Summary
 drop column pct_30
alter table Portfolio_Summary
 drop column pct_60
alter table Portfolio_Summary
 drop column pct_90
alter table Portfolio_Summary
 drop column pct_120
alter table Portfolio_Summary
 drop column pct_REO
alter table Portfolio_Summary
 drop column pct_Foreclosure
alter table Portfolio_Summary
 drop column pct_Bankruptcy
alter table Portfolio_Summary
 drop column pct_FHA_PreConveyance

alter table Portfolio_Summary
add pct_prepaid as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Prepaid or Current],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_current as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Current Month],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_30 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([30 Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_60 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([60 Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_90 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([90 Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_120 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([120+ Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_REO as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([REO],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_Foreclosure as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Foreclosure],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_Bankruptcy as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Bankruptcy],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary
add pct_FHA_PreConveyance as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([FHA_PreConveyance],0) / isnull([Active],1),1) ) END

 alter table Portfolio_Summary
 drop column UPB_pct_prepaid
alter table Portfolio_Summary
 drop column UPB_pct_current
alter table Portfolio_Summary
 drop column UPB_pct_30
alter table Portfolio_Summary
 drop column UPB_pct_60
alter table Portfolio_Summary
 drop column UPB_pct_90
alter table Portfolio_Summary
 drop column UPB_pct_120
alter table Portfolio_Summary
 drop column UPB_pct_REO
alter table Portfolio_Summary
 drop column UPB_pct_Foreclosure
alter table Portfolio_Summary
 drop column UPB_pct_Bankruptcy
alter table Portfolio_Summary
 drop column UPB_pct_FHA_PreConveyance

alter table Portfolio_Summary
add UPB_pct_prepaid as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Prepaid or Current],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_current as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Current Month],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_30 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_30 Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_60 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_60 Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_90 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_90 Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_120 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_120+ Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_REO as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_REO],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_Foreclosure as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Foreclosure],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_Bankruptcy as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Bankruptcy],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary
add UPB_pct_FHA_PreConveyance as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_FHA_PreConveyance],0) / isnull([UPB_Active],1),1) ) END

select * from Portfolio_Summary 


--- **********  INVESTOR ********** ---
alter table Portfolio_Summary_investor
 drop column pct_prepaid
alter table Portfolio_Summary_investor
 drop column pct_current
alter table Portfolio_Summary_investor
 drop column pct_30
alter table Portfolio_Summary_investor
 drop column pct_60
alter table Portfolio_Summary_investor
 drop column pct_90
alter table Portfolio_Summary_investor
 drop column pct_120
alter table Portfolio_Summary_investor
 drop column pct_REO
alter table Portfolio_Summary_investor
 drop column pct_Foreclosure
alter table Portfolio_Summary_investor
 drop column pct_Bankruptcy
alter table Portfolio_Summary_investor
 drop column pct_FHA_PreConveyance

alter table Portfolio_Summary_Investor
add pct_prepaid as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Prepaid or Current],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_current as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Current Month],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_30 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([30 Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_60 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([60 Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_90 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([90 Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_120 as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([120+ Days Delinquent],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_REO as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([REO],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_Foreclosure as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Foreclosure],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_Bankruptcy as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([Bankruptcy],0) / isnull([Active],1),1) ) END
alter table Portfolio_Summary_Investor
add pct_FHA_PreConveyance as CASE WHEN isnull([Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([FHA_PreConveyance],0) / isnull([Active],1),1) ) END

alter table Portfolio_Summary_investor
 drop column UPB_pct_prepaid
alter table Portfolio_Summary_investor
 drop column UPB_pct_current
alter table Portfolio_Summary_investor
 drop column UPB_pct_30
alter table Portfolio_Summary_investor
 drop column UPB_pct_60
alter table Portfolio_Summary_investor
 drop column UPB_pct_90
alter table Portfolio_Summary_investor
 drop column UPB_pct_120
alter table Portfolio_Summary_investor
 drop column UPB_pct_REO
alter table Portfolio_Summary_investor
 drop column UPB_pct_Foreclosure
alter table Portfolio_Summary_investor
 drop column UPB_pct_Bankruptcy
alter table Portfolio_Summary_investor
 drop column UPB_pct_FHA_PreConveyance

alter table Portfolio_Summary_Investor
add UPB_pct_prepaid as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Prepaid or Current],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_current as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Current Month],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_30 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_30 Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_60 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_60 Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_90 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_90 Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_120 as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_120+ Days Delinquent],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_REO as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_REO],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_Foreclosure as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Foreclosure],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_Bankruptcy as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_Bankruptcy],0) / isnull([UPB_Active],1),1) ) END
alter table Portfolio_Summary_Investor
add UPB_pct_FHA_PreConveyance as CASE WHEN isnull([UPB_Active],1) = 0.00 THEN 0 ELSE (CONVERT(DECIMAL(10,2),100.0 * isnull([UPB_FHA_PreConveyance],0) / isnull([UPB_Active],1),1) ) END

select * from Portfolio_Summary_Investor
