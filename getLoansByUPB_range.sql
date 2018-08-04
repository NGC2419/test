USE BDESime
GO
DECLARE @localUPBflag money = 0
-- UPBflag Requirements =0 (0),   >= 0  (1),  > .01  (2)

IF @localUPBflag = 0  BEGIN  -- 0 balance
SELECT [First Principal Balance], total = count([First Principal Balance]) 
FROM bdesime.dbo.loan 
WHERE convert(money,[First Principal Balance]) = 0.0
GROUP BY [First Principal Balance]
END

IF @localUPBflag <> 0 BEGIN 
SELECT [First Principal Balance], total = count([First Principal Balance]) 
FROM bdesime.dbo.loan 
WHERE convert(money,[First Principal Balance]) >= CASE WHEN @localUPBflag = 1 THEN 0.0  WHEN @localUPBflag = 2 THEN 0.02 END
GROUP BY [First Principal Balance]
END


--	IF @localUPBflag = 0  BEGIN (SELECT * FROM #Resultset WHERE convert(money,[UPB]) = 0.0) END   
--	IF @localUPBflag <> 0 BEGIN (SELECT * FROM #Resultset WHERE convert(money,[UPB]) >= CASE WHEN @localUPBflag = 1 THEN 0.0  WHEN @localUPBflag = 2 THEN 0.02 END) END
