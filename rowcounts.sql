
/*
select count(*) from #transform where loannumber is null
select distinct date, TotalNewLoans from #NewLoans
Date		TotalNewLoans  null
2017-05-31	3650		10636
2017-06-30	3305		8246
2017-07-31	3466		5603
2017-08-31	3725		3006

select  distinct date, TotalClosed from #closedloans 
date	TotalClosed
2017-06-30	964
2017-07-31	867
2017-08-31	985

select distinct date, count(date) from #closedloans group by date
Date		Closed Loans
2017-06-30	963
2017-08-31	2947
2017-07-31	1730
*/


(16995 rows affected)

(5 rows affected)

(0 rows affected)

(351997 rows affected)

(351997 rows affected)

(84236 rows affected)

(86626 rows affected)

(89269 rows affected)

(91866 rows affected)
Warning: Null value is eliminated by an aggregate or other SET operation.

(94872 rows affected)

(3725 rows affected)

(3466 rows affected)

(3305 rows affected)

(3650 rows affected)

(3725 rows affected)

(3462 rows affected)

(3298 rows affected)

(3629 rows affected)

(91866 rows affected)

(89269 rows affected)

(86626 rows affected)

(84236 rows affected)

(35116 rows affected)

(94872 rows affected)

(985 rows affected)

(867 rows affected)

(964 rows affected)

(833 rows affected)

(985 rows affected)

(867 rows affected)

(964 rows affected)

(833 rows affected)

(5640 rows affected)

(5640 rows affected)

(5640 rows affected)

(5640 rows affected)

(5640 rows affected)

(0 rows affected)

(2947 rows affected)

(1730 rows affected)

(963 rows affected)

(5640 rows affected)

(5640 rows affected)

(94872 rows affected)

(10976 rows affected)
