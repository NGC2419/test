	
  SELECT DISTINCT x.[Type]
		,x.TemplateID
  INTO #templates
  FROM (
	-- LM template population
   	select distinct [Type] = 'LM'
		, TemplateID = convert(varchar(100),[lm template id])
   FROM bdesime.dbo.[loss_mitigation] 
	-- REO template population
   UNION
	select DISTINCT [Type] = 'Reo'
		, TemplateID = convert(varchar(100),[reo template id])
    FROM  bdesime.dbo.[REO]  
	UNION
	-- FC
		SELECT Type = 'FC'
		, TemplateID = convert(varchar(100),[fc template id])
		FROM  bdesime.dbo.[foreclosure] f (nolock) 
	) x
	ORDER BY x.[Type],x.TemplateID
	
	SELECT y.StepCode
			,y.StepDescription
	INTO #Steps 
	FROM (
	select DISTINCT StepCode		 = rs.[reo step code] 
			,StepDescription = tsi.[tsi step description] 	   
    FROM bdesime.dbo.REO rs
	JOIN bdesime.dbo.template_step_info tsi ON tsi.[tsi step code] = rs.[reo step code]
	--where rs.[reo step code] = 'z90'
	UNION
	select DISTINCT StepCode		 = fs.[step code] 
			,StepDescription = tsi.[tsi step description] 	   
	 FROM bdesime.dbo.foreclsure_step fs 
	JOIN bdesime.dbo.template_step_info tsi ON tsi.[tsi step code] = fs.[step code]
	--where fs.[step code] = 'z90'
	UNION
	select DISTINCT StepCode		 = ls.[ls step code] 
			,StepDescription = tsi.[tsi step description]
			--,TemplateID = [Loss mit template name] 	   
	FROM bdesime.dbo.loss_mit_steps ls 
	--FROM bdesime.dbo.loss_mitigation lm
	JOIN bdesime.dbo.template_step_info tsi ON tsi.[tsi step code] = ls.[ls step code]
--	where ls.[ls step code] = 'z90'
	) y
	ORDER BY y.[StepCode], y.StepDescription

	select * from #steps where stepdescription like '%conv%'
	
	select * from #templates
	select * from #steps 
	
	IF object_id('tempdb.dbo.#Steps') IS NOT NULL Drop Table #Steps
	IF object_id('tempdb.dbo.#Templates') IS NOT NULL Drop Table #Templates


	
	--select * FROM bdesime.dbo.foreclsure_step fs where [loan number] = '0002388379' and [step code] in ('z90','z91','z92')
