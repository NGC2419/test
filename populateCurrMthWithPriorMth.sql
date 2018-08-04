declare @yyyymm int = 201601
print  CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END


UPDATE DateDimension
set NbrProcessDaysPriorMth = d2.NbrProcessDaysPriorMth
FROM DateDimension d
JOIN (
SELECT distinct C_YYYYMM = c.YYYYMM, c.NbrProcessDays, NbrProcessDaysPriorMth =p.NbrProcessDays, P_YYYYMM = p.YYYYMM
FROM      (-- Get records from the Current month from the OriginalFact table.
     SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth 
      FROM  DateDimension
      WHERE  yyyymm IN (@yyyymm)
      ) c -- Current
   CROSS APPLY (-- Get records from the Prior month.
     SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth 
      FROM  DateDimension
      WHERE  yyyymm = convert(int,CASE WHEN substring(convert(char(6),@YYYYMM),5,2)='01' THEN @yyyymm - 89 ELSE @yyyymm - 1 END)
      ) p -- Prior
   group by C.YYYYMM, c.NbrProcessDays,p.YYYYMM,p.NbrProcessDays
   ) d2
   ON d.YYYYMM = d2.C_YYYYMM

SELECT distinct YYYYMM, NbrProcessDays, NbrProcessDaysPriorMth  from DateDimension where YYYYMM = @yyyymm