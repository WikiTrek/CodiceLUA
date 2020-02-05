-- Auto upload by PageToGitHub on 2020-02-06T00:10:43+01:00
-- This code from page Modulo:DTEpisodio
-- This code comes from Modulo:DTEpisodio
local p = {}
function p.GetActors()
	-- Personaggio (P10)
	-- Prefisso (P15)
	-- Interpreti (P21)
	local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then
		item = 'Q1'
	end
	if not item then return ':-(' end
	local results = {}
	local statements = mw.wikibase.getAllStatements(item, 'P21')
	for _, statement in pairs(statements) do
		local Result = {}
		local actorQ = statement.mainsnak.datavalue['value']['id']
		-- Se servisse l'entità, bisognerebbe fare
		-- local actorEntity = mw.wikibase.getEntity(actorQ)
		-- local actorLabel = actorEntity:getLabel()
		
		-- Se tutti gli attori avessero SiteLink
		-- mw.wikibase.getSitelink(actorQ)
		local actorLabel = mw.wikibase.getLabel(actorQ)
		
		local CharQ
		local CharEntity
		local CharLabel
		local CharLabelEntity
		local CharLink
		if statement['qualifiers']['P10'] then
			CharQ = statement['qualifiers']['P10'][1].datavalue['value']['id']
			CharEntity = mw.wikibase.getEntity(CharQ)
			CharLabelEntity = CharEntity:getLabel()
			
			if statement['qualifiers']['P20'] then
				CharLabel = statement['qualifiers']['P20'][1].datavalue['value']
			else
				CharLabel = CharLabelEntity
			end
			--[==[
			CharLink = mw.wikibase.getSitelink(CharQ)
			if not CharLink then
				CharLink = CharLabelEntity
			end]==]
			
			CharLink = mw.wikibase.getSitelink(CharQ) or CharLabelEntity
			
		else
			CharLabel = "''Sconosciuto''"
		end
				
		local Prefix
		if statement['qualifiers']['P15'] then
			Prefix = statement['qualifiers']['P15'][1].datavalue['value'] .. ' '
		else
			Prefix = ''
		end
		
		local Suffix
		if statement['qualifiers']['P19'] then
			Suffix = ' ' .. statement['qualifiers']['P19'][1].datavalue['value']
		else
			Suffix = ''
		end
		
		local AppearanceType
		if statement['qualifiers']['P22'] then
			AppearanceType = mw.wikibase.getLabel(statement['qualifiers']['P22'][1].datavalue['value']['id'])
		else
			AppearanceType = "''Nessun tipo''"
		end
		
		Result['Character'] = Prefix .. '[[' .. CharLink .. '|' .. CharLabel .. ']]' .. Suffix
		Result['Actor'] = '[[' .. actorLabel .. ']]'
		Result['Type'] = AppearanceType
		
		results[#results + 1] = Result
	end
	return results
end
function p.ListFirstAir(frame)
	local CurrItem = mw.wikibase.getEntityIdForCurrentPage()
	if not CurrItem then
		CurrItem = 'Q1'
	end
	
	local Results = {}
	local Statements = mw.wikibase.getAllStatements(CurrItem, 'P2')
	for _, Statement in pairs(Statements) do
		local Result
		Result = '<li>' .. frame:expandTemplate{ title = 'TimeL', args = {Tipo='ITEstesa', Data=Statement['mainsnak'].datavalue['value'].time} } .. " su ''" .. Statement['qualifiers']['P4'][1].datavalue['value'] .. "'' (" .. Statement['qualifiers']['P34'][1].datavalue['value'] .. ")</li>"
		
		Results[#Results + 1] = Result
	end
	
	return '<ul>' .. table.concat(Results, string.char(10)) .. '</ul>'
end
function p.ListActors(frame)
	local Actors = p.GetActors()
	local Results = {}
	local Groups = {}
	local FinalList = ""
	
	-- table.sort(Attori)
	for _, Role in pairs(Actors) do
		if not Groups[Role.Type] then
			Groups[Role.Type] = '* ' .. Role.Character .. ': ' .. Role.Actor
		else
			Groups[Role.Type] = Groups[Role.Type] .. string.char(10) .. '* ' .. Role.Character .. ': ' .. Role.Actor
		end
		
		Results[#Results + 1] = '* ' .. Role.Character .. ': ' .. Role.Actor .. frame:expandTemplate{ title = 'Etichetta', args = {Tipo=Role.Type} } 			
	end
	
	for Key, Group in pairs(Groups) do
		FinalList = FinalList .. "'''''" .. frame:expandTemplate{ title = 'Etichetta', args = {Tipo=Key} } .. "'''''" .. string.char(10) .. Group .. string.char(10) .. string.char(10)
	end
	-- return table.concat(Results, string.char(10))
	
	return FinalList
end
function p.LinkFromP(Property)
	local EpisodeTitle
	local Link
	local item = mw.wikibase.getEntity() --local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then return '' end
	if not item['claims'][Property] then
		EpisodeTitle = "''Nessuno''"
		Link = EpisodeTitle
	else
		EpisodeTitle = item['claims'][Property][1]['mainsnak'].datavalue['value']
		Link = '[[' .. EpisodeTitle .. '|' .. EpisodeTitle .. ']]'
	end
	return Link
end
function p.LinkPrevious()
	--[===[
	local EpisodeTitle
	local Link
	local item = mw.wikibase.getEntity() --local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then return '' end
	if not item['claims']['P7'][1] then
		EpisodeTitle = "''Nessuno''"
		Link = EpisodeTitle
	else
		EpisodeTitle = item['claims']['P7'][1]['mainsnak'].datavalue['value']
		Link = '[[' .. EpisodeTitle .. '|' .. EpisodeTitle .. ']]'
	end
	]===]
	return p.LinkFromP('P7')
end
function p.LinkNext()
	return p.LinkFromP('P23')
end
function p.SeasonInfo()
	-- |BoxTitolo=Stagione 2 di Discovery
	-- |Icona={{#statements:Icona|from=Q1}}
	--[===[
	local SeasonNumber
	local SeriesQ
	local SeriesName
	local FileName
	]===]
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	local SeasonData = p.SeasonInfoRaw(Item)
	
	--[===[
	SeasonNumber = Item['claims']['P18'][1]['mainsnak'].datavalue['value'].amount
	SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	SeriesName = mw.wikibase.getLabel(SeriesQ)
	FileName = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	]===]

	-- return mw.text.nowiki("|BoxTitolo=Stagione " .. SeasonData.SeasonNumber .. " di ''" .. SeasonData.SeriesAbbr .. "''|FileIcona=" .. SeasonData.FileName)
	return "Stagione " .. SeasonData.SeasonNumber .. " di ''" .. SeasonData.SeriesAbbr
	
end
function p.SeasonInfoRaw(Entity)
	--[===[
	local SeasonNumber
	local SeriesQ
	local SeriesName
	local SeriesAbbr
	local FileName
	]===]
	local Result = {}
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = Entity
	end

	Result['SeasonNumber'] = string.format('%u', Item['claims']['P18'][1]['mainsnak'].datavalue['value'].amount)
	SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	Result['SeriesName'] = mw.wikibase.getLabel(SeriesQ)
	Result['FileName'] = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	Result['SeriesAbbr'] = mw.wikibase.getEntity(SeriesQ)['claims']['P24'][1]['mainsnak'].datavalue['value']
	
	return Result
end
function p.FileIcon()
	-- |FileIcona=dsg.png
	local SeriesQ
	local FileName
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	FileName = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	
	return FileName
end
function p.Incipit(frame)
	local SeasonData = p.SeasonInfoRaw()
	
	return frame:expandTemplate{ title = 'DataBoxEpisodio' } .. string.char(10) .. "[[" .. mw.title.getCurrentTitle().text .. "]] è un episodio della stagione " .. SeasonData.SeasonNumber .. " di ''[[" .. SeasonData.SeriesName .. "]]''." .. string.char(10)
end
return p