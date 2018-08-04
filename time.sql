



===============================================================================================
Function FormatTimeSpan(TS as TimeSpan) as String
Dim DT as new DateTime(TS.Ticks)
Return DT.ToString("HH:mm:ss:fff")
End Function

=IIF(IsNothing(Timespan.FromTicks(avg(Fields!Average_Handle_Time_Per_Call.Value)))
, Nothing
, Code.FormatTimeSpan(Timespan.FromTicks(avg(Fields!Average_Handle_Time_Per_Call.Value))))

=IIF(IsNothing(Timespan.FromTicks(sum(Fields!Total_Time_on_Calls.Value)))
, Nothing
, Code.FormatTimeSpan(Timespan.FromTicks(sum(Fields!Total_Time_on_Calls.Value))))

===============================================================================================
-- convert seconds to hhmmss
=Format(DateAdd("s", Fields!TotalTime.Value, "00:00:00"), "HH:mm:ss"), 

===============================================================================================