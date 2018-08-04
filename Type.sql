select month(LoanDate), Total = sum(NewLoans), DLQStatusFrom = 'NewLoans' from bde_data.dbo.Portfolio_Summary WHERE Client = 'tms000' and loandate <= '2016-02-29' group by month(LoanDate)
select LoanDate, Total = sum(NewLoans), DLQStatusFrom = 'NewLoans' from bdesime.dbo.Portfolio_Summary_type WHERE Client = 'tms000' and loandate <= '2016-02-29' group by LoanDate
select LoanDate, Total = sum(NewLoans), DLQStatusFrom = 'NewLoans' from BDE_Data.dbo.Portfolio_Summary_Investor WHERE Client = 'tms000' and loandate <= '2016-02-29' group by LoanDate


select LoadDate, LoanDate1 = LoanDate,* from bde_data.dbo.Portfolio_Summary WHERE Client = 'tms000' order by loandate desc --and loandate <= '2016-02-29' 
select LoadDate, LoanDate1 = LoanDate,* from bde_data.dbo.Portfolio_Summary_Investor WHERE Client = 'tms000'  order by loandate desc  --and loandate <= '2016-02-29' 
select LoadDate, LoanDate1 = LoanDate,* from bdesime.dbo.Portfolio_Summary_type WHERE Client = 'tms000'  order by loandate desc  --and loandate <= '2016-02-29' 
