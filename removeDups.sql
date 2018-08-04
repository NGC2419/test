;WITH cte AS (
  SELECT[foo], [bar], 
     row_number() OVER(PARTITION BY foo, bar ORDER BY baz) AS [rn]
  FROM TABLE
)
DELETE cte WHERE [rn] > 1