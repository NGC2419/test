USE BDE_DATA
GO
--This job inserts transfer counts into a snapshot table
DECLARE @enddate as datetime = getdate(), @Client_Code varchar(200) = 'all'
DECLARE @localEndDate as datetime = @enddate
print @localEndDate
	
	/* Transfers In/Out */

	  	-- prior date algorithm
	declare @priordate date = dateadd(day,-1,@localenddate)
		IF  ( DATENAME(weekday,@localenddate) = 'Monday' ) BEGIN SET @priordate = CAST(@localenddate-3 as date) END
		IF  ( DATENAME(weekday,@localenddate) = 'Sunday' ) BEGIN SET @priordate = CAST(@localenddate-2 as date) END
		IF  ( DATENAME(weekday,@localenddate) IN ('Tuesday','Wednesday','Thursday','Friday','Saturday')) BEGIN SET @priordate = CAST(@localenddate-1 as date) END
		
		
		INSERT INTO transfers_count_in_out(LoanDate, xfersInOut)
		exec [dbo].[sp_insert_transfers_in_out] @localEndDate,@Client_Code

	select distinct LoanDate, xfersInOut from transfers_count_in_out order by LoanDate desc


	
/*
select * from transfers_count_in_out order by LoanDate desc
update transfers_count_in_out set xfersInOut = '-1' where LoanDate = '6/30/2016'
*/