declare @startDate date = '7/31/2017', @endDate date = '8/2/2017', @server varchar(20) = convert(varchar(200),(SELECT SERVERPROPERTY('ServerName')))
select * from (
select distinct [table] = @server + ' -  bdesime.dbo.delinquency_snapshot', loanDate = max([loan date]), UPB = sum([first principal balance]), loans = count([loan number]) 
from bdesime.dbo.delinquency_snapshot (nolock) where [first principal balance] > 0 AND convert(date,[loan date]) between @startDate and @endDate group by [loan date]
UNION
select [table] = @server + ' -  bde_data.dbo.portfolio_summary', loanDate = max([loandate]), UPB = sum(UPB), loans = sum(active) + sum(reo) from bde_data.dbo.portfolio_summary (nolock) where [loandate]  between @startDate and @endDate group by loandate 
UNION
select [table] = @server + ' -  bde_data.dbo.portfolio_summary_investor',loanDate = max([loandate]), UPB = sum(UPB), loans = sum(active) + sum(reo)  from bde_data.dbo.portfolio_summary_investor (nolock) where [loandate]  between @startDate and @endDate group by loandate
UNION
select [table] = @server + ' -  bdesime.dbo.portfolio_summary_type',loanDate = max([loandate]), UPB = sum(UPB), loans = sum(active) + sum(reo)  from bdesime.dbo.portfolio_summary_type (nolock) where [loandate]  between @startDate and @endDate group by loandate
) s
order by loandate,[table] desc
