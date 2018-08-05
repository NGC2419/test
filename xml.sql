Render query results as XML

SQL,XML

This simple script renders the query results as XML:
-- Declare a variable with the XML datatype
DECLARE @myXml xml 
-- Use FOR XML AUTO syntax
SET @myXml = (SELECT [states] FROM [pharmacy] Order By [states] FOR XML AUTO)
-- Retrieve the results
select @myXml
<pharmacy states="Alabama" />
<pharmacy states="Arizona" />
<pharmacy states="Arkansas" />
. . .