USE [BDE_Data]
GO
CREATE PROCEDURE [dbo].[sp_DataDictionary] (@tableName varchar(200)) 
AS
-- ========================================================================================
-- Author:		Susan Delaney
-- Create date: 8/14/2017
-- Modified:   
-- Description: Retrieves MSP data dictionary definitions
-- ========================================================================================
 -- exec dbo.sp_DataDictionary 'loan'
 Select [Table Name]
		,[Field Level / Name]	
		,[Business Element Name]
		,[Field Description]
		,[SqlDataType]
 from datadictionary163 
 where [table name] = @tableName

 -- 			  select * from bdesime.sime.DictionaryItems