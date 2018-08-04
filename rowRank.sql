		   -- tax disbursement info for upcoming 6 months
			SELECT ln_no, tx_disb_am, tx_disb_due_dt, tx_disb_due_dt_mm, tx_disb_due_dt_yyyy 
			INTO #Taxes
				FROM (
					   select ln_no
							, tx_disb_am
							, tx_disb_due_dt
							, tx_disb_due_dt_mm = month(tx_disb_due_dt) 
							, tx_disb_due_dt_yyyy = year(tx_disb_due_dt) 
						   ,ROW_NUMBER() OVER (PARTITION BY Month(tx_disb_due_dt) ORDER BY month(tx_disb_due_dt) DESC) 'RowRank'
					FROM bde_data.dbo.tax 
				   WHERE [ln_no] in (select distinct [Loan Number] from #resultset)
					 AND convert(date,tx_disb_due_dt) between @localBaseLineDateBOM AND @localEndDate
					 AND month(tx_disb_due_dt) IN (@month0,@month1,@month2,@month3,@month4,@month5,@month6)
					)sub
				WHERE RowRank = 1 
