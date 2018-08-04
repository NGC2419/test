	select agent
            --, reason_code
            , [dbo].ConvertTimeToHHMMSS(sum(agent_state_time_secs), 'second') AgentStateTime
			, [dbo].ConvertTimeToHHMMSS(sum(login_time_secs), 'second') LoginTime
			, [dbo].ConvertTimeToHHMMSS(sum(ready_time_secs), 'second') ReadyTime
			, [dbo].ConvertTimeToHHMMSS(sum(not_ready_time_secs), 'second') NotReadyTime
			, sum(calls) as Calls
            from [BDE_Data].[dbo].five9_AgentTransactionalSummary
            where data_from >='20160601' AND data_until <= getdate()
            group by agent
            --, reason_code
            order by 1,2
