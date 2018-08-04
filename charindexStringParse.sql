--  T-SQL applying charindex for string parsing


DECLARE  @SearchingFor VARCHAR(256)  = 'CCCC-DDDDDDD-AAA-BBBBB' 

SELECT [Part1] = LEFT(@SearchingFor,CHARINDEX('-',@SearchingFor) - 1), 

       [Part2] = SUBSTRING(@SearchingFor,CHARINDEX('-',@SearchingFor) + 1, 
                           CHARINDEX('-',@SearchingFor,CHARINDEX('-',
                           @SearchingFor) + 1) - (CHARINDEX('-',@SearchingFor) + 1)), 

       [Part3] = SUBSTRING(@SearchingFor,CHARINDEX('-',
                           @SearchingFor,CHARINDEX('-',@SearchingFor) + 1) + 1, 
                           DATALENGTH(@SearchingFor) - CHARINDEX('-',
                           @SearchingFor,CHARINDEX('-',@SearchingFor) + 1) - 
                           CHARINDEX('-',REVERSE(@SearchingFor))), 

       [Part4] = RIGHT(@SearchingFor,CHARINDEX('-',REVERSE(@SearchingFor)) - 1) 

GO
