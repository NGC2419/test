
DECLARE  @SearchingFor VARCHAR(30)  = 'Spanish IVR Pressed' 

SELECT top 10 [I found it to the left] = LEFT([IVR Path],CHARINDEX(' @SearchingFor',[IVR Path]) - 100) from five9_activity

--SELECT [I found it to the right] = Right(@SearchingFor,CHARINDEX('IVR',@SearchingFor) - 1) 
 

GO

--select top 3 * from five9_activity
