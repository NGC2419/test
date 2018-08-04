;with a as (
		SELECT [SID]
				,[Period]
				,[TotalAckMTD]		 
				,[Ack1_3_DaysMTD]	 
				,[Ack4_5_DaysMTD]	 
				,[Ack1_DaysMTD]		 
				,[Ack2_DaysMTD]		 
				,[Ack3_DaysMTD]		 
				,[Ack4_DaysMTD]		 
				,[Ack5_DaysMTD]		 
				,[AckOverdueMTD]	 
				,[AckPassMTD]		 
				,[AckFailMTD]		 
		,rn1=row_number() over (partition by [SID], PERIOD,TotalAckMTD order by [SID])
		from #Resultset
		where [SID] is not null and TotalAckMTD is not null
		), b as (
		SELECT [SID]
				,[Period]
				,[TotalAckMTD]		 
				,[Ack1_3_DaysMTD]	 
				,[Ack4_5_DaysMTD]	 
				,[Ack1_DaysMTD]		 
				,[Ack2_DaysMTD]		 
				,[Ack3_DaysMTD]		 
				,[Ack4_DaysMTD]		 
				,[Ack5_DaysMTD]		 
				,[AckOverdueMTD]	 
				,[AckPassMTD]		 
				,[AckFailMTD]		 
		,rn2=row_number() over (partition by [SID], PERIOD,TotalAckMTD	order by [SID])
		from #Resultset
		where [SID] is not null and TotalAckMTD is not null
		)
		select  a.[SID]
				, a.Period
				, a.TotalAckMTD
				, [Ack1_3_DaysMTD] = max(a.[Ack1_3_DaysMTD]) 
				, [Ack4_5_DaysMTD] = max(a.[Ack4_5_DaysMTD])
				, [Ack1_DaysMTD] = max(a.[Ack1_DaysMTD])
				, [Ack2_DaysMTD] = max(a.[Ack2_DaysMTD])
				, [Ack3_DaysMTD] = max(a.[Ack3_DaysMTD])
				, [Ack4_DaysMTD] = max(a.[Ack4_DaysMTD])
				, [Ack5_DaysMTD] = max(a.[Ack5_DaysMTD])
				, [AckOverdueMTD] = max(a.[AckOverdueMTD])
				, [AckPassMTD] = max(a.[AckPassMTD]) 
				, [AckFailMTD] = max(a.[AckFailMTD])		 
		from a 
		group by  a.[SID], a.Period, a.TotalAckMTD
	    order by  a.[SID], a.Period, a.TotalAckMTD
	