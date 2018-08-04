
select [date], [call id], [ivr path]
into #ivr
from five9_activity
where [ivr path] like '%Spanish IVR Pressed%' 
and [date] between '3/20/2017' and '3/24/2017'

DECLARE  @SearchingFor VARCHAR(256)  = 'Spanish IVR Pressed' 

select [date], [call id], FoundIt = patindex(@SearchingFor,[ivr path]) 
,[ivr path]
from five9_activity
where [date] between '3/20/2017' and '3/24/2017'
and [ivr path] like '%Spanish IVR Pressed%' 


-- SELECT [I found it to the left of IVR] = LEFT(@SearchingFor,CHARINDEX('IVR',@SearchingFor) - 1) 
-- SELECT [I found it to the right of IVR] = Right(@SearchingFor,CHARINDEX('IVR',@SearchingFor) - 1) 



drop table #ivr

