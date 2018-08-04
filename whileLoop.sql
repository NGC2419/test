
select  convert(int,concat(convert(char(4), datepart(year,'1/1/2016')), convert(varchar(2),CASE WHEN datepart(month,'1/1/2016') > 9 THEN convert(varchar(2),datepart(month,'1/1/2016'))	ELSE '0' + convert(char(1),datepart(month,'1/1/2016')) END)))

	/* No transactions during calendar month  */
	  -- 1) check for no payment transaction during each calendar month
	  -- 2) add a placeholder for transactions missing from the 12-month population resulting from prepayment in a previous month or payment delinquency	
	SELECT [Month],BOM=FirstDayOfMonth,EOM=LastDayOfMonth into #missingMonths from #Months where [Month] NOT IN (select [Month] from #results) 
	SET @j = @@ROWCOUNT 
	SET @i = 0
	IF @j > 0 
	iF (select count(*) from #results) < 12
	BEGIN
	  BEGIN
		WHILE @i < @j
		  BEGIN
			INSERT INTO #results ([Loan Number],[Pmt Due Date],[Pmt Transaction Date],[Pmt Total Amount],[Pmt Fee Amount])
	  		SELECT DISTINCT [LOAN NUMBER] = @localloannumber
				,[PMT DUE DATE]			  = '1/1/1900'   
				,[PMT TRANSACTION DATE]   = convert(date,BOM) 
				,[PMT TOTAL AMOUNT]		  = 0.00
	 			,[PMT FEE AMOUNT]		  = 0.00
			from #missingMonths 
			set @i = @i + 1
		  END
	  END 
  END