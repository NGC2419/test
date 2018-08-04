For all reports with Loan Numbers you must create a drill through to Loan Detail

DataSet
---------
1. Create a new embedded dataset named ds_URL

2. Query Type is Text

3. Add this query:   SELECT   dbo.ufnGetgetloanlink() AS URL

4. Field name is URL



Parameter
-----------
1. Create a hidden Parameter named URL

2. set the Default Values to "Get values from a query"

3. Dataset:  ds_URL

4. Value Field:  URL


Report field
---------------
1. Find the Loan_Number column

2. Click on Text Box Properties

3. Click on Action, Select URL

4. Set this expression for the Hyperlink

="javascript:void(window.open('"+ Parameters!URL.Value & Fields!Loan_Number.Value + "','_blank'))"


