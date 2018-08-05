dynamic selection

/* select the first 10 rows from each table in a database */

EXEC sp_MSforeachtable 'SELECT ''?'' as tableName, * from ?'