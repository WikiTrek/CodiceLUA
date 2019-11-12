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
			
			CharLink = mw.wikibase.getSitelink(CharQ)
			if not CharLink then
				CharLink = CharLabelEntity
			end
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
return p
