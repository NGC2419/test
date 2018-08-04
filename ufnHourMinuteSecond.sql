USE BDE_DATA
GO
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		S. Delaney
-- Create date: 3/16/2016
-- Description:	calculates elapsed time 
-- =============================================
Alter Function dbo.ufnHourMinuteSecond ( @BeginDate DateTime, @EndDate DateTime
) Returns Varchar(10)
As
Begin

Declare @Seconds Int,
@Minute Int,
@Hour Int,
@Elapsed Varchar(10),
@localBeginDate DateTime = @BeginDate,
@localEndDate DateTime = @EndDate

Select @Seconds = ABS(DateDiff(SECOND ,@localBeginDate,@localEndDate))

If @Seconds >= 60
Begin
select @Minute = @Seconds/60
select @Seconds = @Seconds%60

If @Minute >= 60
begin
select @hour = @Minute/60
select @Minute = @Minute%60
end

Else
Goto Final
End

Final:
Select @Hour = Isnull(@Hour,0), @Minute = IsNull(@Minute,0), @Seconds =               IsNull(@Seconds,0)
select @Elapsed = Cast(@Hour as Varchar) + ':' + Cast(@Minute as Varchar) + ':' +     Cast(@Seconds as Varchar)

Return (@Elapsed)
End

