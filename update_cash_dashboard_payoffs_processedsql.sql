use bde_data
go

update cash_dashboard
set [Payoffs Processed] = '4016915'
where convert(date,[Process Date]) = '9/27/2016'

update cash_dashboard
set [Payoffs Processed] = '50007099'
where convert(date,[Process Date]) = '9/28/2016'

update cash_dashboard
set [Payoffs Processed] = '31382527'
where convert(date,[Process Date]) = '9/29/2016'

update cash_dashboard
set [Payoffs Processed] = '68940206'
where convert(date,[Process Date]) = '9/30/2016'

update cash_dashboard
set [Payoffs Processed] = '42104508'
where convert(date,[Process Date]) = '10/3/2016'

update cash_dashboard
set [Payoffs Processed] = '15987517'
where convert(date,[Process Date]) = '10/4/2016'

update cash_dashboard
set [Payoffs Processed] = '12954833'
where convert(date,[Process Date]) = '10/5/2016'

update cash_dashboard
set [Payoffs Processed] = '5468348'
where convert(date,[Process Date]) = '10/6/2016'

update cash_dashboard
set [Payoffs Processed] = '15014696'
where convert(date,[Process Date]) = '10/7/2016'

update cash_dashboard
set [Payoffs Processed] = '13906156'
where convert(date,[Process Date]) = '10/11/2016'

update cash_dashboard
set [Payoffs Processed] = '11697972'
where convert(date,[Process Date]) = '10/12/2016'

update cash_dashboard
set [Payoffs Processed] = '17821978'
where convert(date,[Process Date]) = '10/13/2016'

update cash_dashboard
set [Payoffs Processed] = '15276315'
where convert(date,[Process Date]) = '10/14/2016'

update cash_dashboard
set [Payoffs Processed] = '16343391'
where convert(date,[Process Date]) = '10/17/2016'

update cash_dashboard
set [Payoffs Processed] = '15602899'
where convert(date,[Process Date]) = '10/18/2016'

update cash_dashboard
set [Payoffs Processed] = '17452357'
where convert(date,[Process Date]) = '10/19/2016'

update cash_dashboard
set [Payoffs Processed] = '23561992'
where convert(date,[Process Date]) = '10/20/2016'

update cash_dashboard
set [Payoffs Processed] = '19326412'
where convert(date,[Process Date]) = '10/21/2016'

update cash_dashboard
set [Payoffs Processed] = '25871652'
where convert(date,[Process Date]) = '10/24/2016'

update cash_dashboard
set [Payoffs Processed] = '35929425'
where convert(date,[Process Date]) = '10/25/2016'

update cash_dashboard
set [Payoffs Processed] = '23671239'
where convert(date,[Process Date]) = '10/26/2016'

update cash_dashboard
set [Payoffs Processed] = '27075671'
where convert(date,[Process Date]) = '10/27/2016'

update cash_dashboard
set [Payoffs Processed] = '35625490'
where convert(date,[Process Date]) = '10/28/2016'

update cash_dashboard
set [Payoffs Processed] = '58512542.4'
where convert(date,[Process Date]) = '10/31/2016'

update cash_dashboard
set [Payoffs Processed] = '52650048.69'
where convert(date,[Process Date]) = '11/1/2016'

update cash_dashboard
set [Payoffs Processed] = '15436933.18'
where convert(date,[Process Date]) = '11/2/2016'

update cash_dashboard
set [Payoffs Processed] = '13634459.21'
where convert(date,[Process Date]) = '11/3/2016'

update cash_dashboard
set [Payoffs Processed] = '12278278.52'
where convert(date,[Process Date]) = '11/4/2016'

update cash_dashboard
set [Payoffs Processed] = '13933142.41'
where convert(date,[Process Date]) = '11/7/2016'

update cash_dashboard
set [Payoffs Processed] = '10323034.99'
where convert(date,[Process Date]) = '11/8/2016'

update cash_dashboard
set [Payoffs Processed] = '10017347.23'
where convert(date,[Process Date]) = '11/9/2016'

update cash_dashboard
set [Payoffs Processed] = '10929848.3'
where convert(date,[Process Date]) = '11/10/2016'

update cash_dashboard
set [Payoffs Processed] = '20553618.76'
where convert(date,[Process Date]) = '11/14/2016'

update cash_dashboard
set [Payoffs Processed] = '17450854.5'
where convert(date,[Process Date]) = '11/15/2016'

update cash_dashboard
set [Payoffs Processed] = '19918843.11'
where convert(date,[Process Date]) = '11/16/2016'

update cash_dashboard
set [Payoffs Processed] = '23331869.77'
where convert(date,[Process Date]) = '11/17/2016'

update cash_dashboard
set [Payoffs Processed] = '20999590.37'
where convert(date,[Process Date]) = '11/18/2016'

update cash_dashboard
set [Payoffs Processed] = '20092689.82'
where convert(date,[Process Date]) = '11/21/2016'

update cash_dashboard
set [Payoffs Processed] = '30875673.82'
where convert(date,[Process Date]) = '11/22/2016'

update cash_dashboard
set [Payoffs Processed] = '23158120.21'
where convert(date,[Process Date]) = '11/23/2016'

update cash_dashboard
set [Payoffs Processed] = '9004156.12'
where convert(date,[Process Date]) = '11/25/2016'

update cash_dashboard
set [Payoffs Processed] = '21616250.04'
where convert(date,[Process Date]) = '11/28/2016'

update cash_dashboard
set [Payoffs Processed] = '46877923.78'
where convert(date,[Process Date]) = '11/29/2016'

update cash_dashboard
set [Payoffs Processed] = '60156323.77'
where convert(date,[Process Date]) = '11/30/2016'

select [payoffs processed], * from  cash_dashboard where convert(date,[Process Date]) between '9/27/2016' and '11/30/2016'