use BDE_DATA

SELECT distinct o.name--, o.id, c.text, o.type 
from sysobjects o 
right join syscomments c 
on o.id = c.id 
where c.text like '%bdesime.dbo.delinquency_snapshot%'
order by o.name

