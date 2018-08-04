
/* Five9 HH:MM:SS conversion to secs so it can by added and convert that value back to hh:mm:ss */
select top 1000 [Date]
,[Call ID]
-- converts hh:mm:ss to seconds
,[Talk Time in seconds]	= sum(DATEDIFF(SECOND, '00:00:00',isnull([Talk Time],'00:00:00')))  
-- converts seconds from previous line of code back to hh:mm:ss to display in the report
 ,[Total Talk Time]			=  LEFT(  CONVERT(time, DATEADD(ms, isnull(  sum(DATEDIFF(SECOND, '00:00:00',isnull([Talk Time],'00:00:00')))      ,0) * 1000, 0), 114)  ,8)
from five9_activity
WHERE convert(date,[Date]) BETWEEN '1/1/2017' AND '1/31/2017'
group by [Date],[Call ID]

-------
select top 1000 [Date]
,[Agent Group]
-- converts hh:mm:ss to seconds
,[Talk Time in seconds]	= sum(DATEDIFF(SECOND, '00:00:00',isnull([Talk Time],'00:00:00')))  
into #agentGroupSeconds
from five9_activity
WHERE convert(date,[Date]) BETWEEN '1/1/2017' AND '1/31/2017'
group by [Date],[Agent Group]
 
select [Date]
,[Agent Group]
,[Talk Time in seconds] = sum([Talk Time in seconds])
-- converts seconds from previous line of code back to hh:mm:ss to display in the report
,[Total Talk Time]	=  LEFT(  CONVERT(time, DATEADD(ms, isnull(       sum([Talk Time in seconds])           ,0) * 1000, 0), 114)  ,8)
--into #agentGroupSeconds
from #agentGroupSeconds
WHERE convert(date,[Date]) BETWEEN '1/1/2017' AND '1/31/2017'
group by [Date],[Agent Group]


drop table #agentGroupSeconds