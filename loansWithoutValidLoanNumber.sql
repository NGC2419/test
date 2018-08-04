select * from bdesime.dbo.delinquency_snapshot where [loan date] = '12/9/2016'
and [MTH STATUS NAME] IN ('120+ Days Delinquent','30 Days Delinquent','60 Days Delinquent','90 Days Delinquent','Pre-30 Days Delinquent')
AND [loan number] NOT IN (select [loan number] from five9_activity where [loan number] is not null and [loan date] > '12/1/2016') 
AND [First Principal Balance] > 0