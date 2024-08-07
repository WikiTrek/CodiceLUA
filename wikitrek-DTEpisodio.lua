-- [P2G] Auto upload by PageToGitHub on 2024-06-17T12:38:04+02:00
-- [P2G] This code from page Modulo:wikitrek-DTEpisodio
-- Keyword: wikitrek
local LabelOrLink = require('Modulo:DTBase').LabelOrLink
local DescrWithTemplate = require('Modulo:DTGenerico').DescrWithTemplate

local p = {}
function p.GetActors(frame, AddSemantic)
	-- Personaggio (P10)
	-- Prefisso (P15)
	-- Interpreti (P21)
	local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then
		item = 'Q1'
	end
	
	if AddSemantic == nil then
		AddSemantic = true
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
		local actorLink = mw.wikibase.getSitelink(actorQ) or "Special:AboutTopic/" .. actorQ
		
		local CharQ
		local CharEntity
		local CharLabel
		local CharLabelEntity
		local CharLink
		local MakeWikiLink
		if statement['qualifiers']['P10'] then
			CharQ = statement['qualifiers']['P10'][1].datavalue['value']['id']
			CharEntity = mw.wikibase.getEntity(CharQ)
			CharLabelEntity = CharEntity:getLabel()
			
			--[==[
			CharLink = mw.wikibase.getSitelink(CharQ)
			if not CharLink then
				CharLink = CharLabelEntity
			end]==]
			
			--CharLink = mw.wikibase.getSitelink(CharQ) or CharLabelEntity
			CharLink = mw.wikibase.getSitelink(CharQ) or "Special:AboutTopic/" .. CharQ
			MakeWikiLink = true
		else
			MakeWikiLink = false
		end
		
		if statement['qualifiers']['P20'] then
			CharLabel = statement['qualifiers']['P20'][1].datavalue['value']
		else
			CharLabel = CharLabelEntity
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
		
		--[=[
		To add additional semantic properties
		{{#set:
		|Emily Coutts=Keyla Detmer
		|Keyla Detmer=Emily Coutts
		}}
		{{#set:|Keyla Detmer=Emily Coutts}}
		]=]
		--Character
		if MakeWikiLink then
			if AddSemantic then
				if string.sub(CharLink, 1, 8) == "Special:" then
					Result['Character'] = Prefix .. '[[' .. CharLink .. '|' .. CharLabel .. ']]' .. Suffix  .. frame:callParserFunction('#set:', 'Personaggio=' .. CharLabel)
				else
					Result['Character'] = Prefix .. '[[' .. CharLink .. '|' .. CharLabel .. ']]' .. Suffix  .. frame:callParserFunction('#set:', 'Personaggio=' .. CharLink)
				end
			else
				Result['Character'] = Prefix .. '[[' .. CharLink .. '|' .. CharLabel .. ']]' .. Suffix
			end
		else
			Result['Character'] = Prefix .. CharLabel .. Suffix
		end
		
		--Actor
		if AddSemantic then
			--Result['Actor'] = '[[Interprete::' .. actorLabel .. ']]' .. frame:callParserFunction('#set:', actorLabel .. '=' .. CharLabel)
			if string.sub(CharLink, 1, 8) == "Special:" then
				Result['Actor'] = '[[' .. actorLink .. '|' .. actorLabel .. ']]' .. frame:callParserFunction('#set:', actorLabel .. '=' .. CharLabel) .. frame:callParserFunction('#set:', 'Interprete=' .. actorLabel)
			else
				Result['Actor'] = '[[' .. actorLink .. '|' .. actorLabel .. ']]' .. frame:callParserFunction('#set:', actorLabel .. '=' .. CharLink) .. frame:callParserFunction('#set:', 'Interprete=' .. actorLabel)
			end
		else
			Result['Actor'] = '[[' .. actorLink .. '|' .. actorLabel .. ']]'
		end
		Result['Type'] = AppearanceType
		
		results[#results + 1] = Result
	end
	return results
end
function p.ListFirstAir(frame, AddSemantic)
	local CurrItem = mw.wikibase.getEntityIdForCurrentPage()
	if not CurrItem then
		return nil
	end
	
	if not AddSemantic then
		AddSemantic = true
	end
	
	local Results = {}
	local Statements = mw.wikibase.getAllStatements(CurrItem, 'P2')
	
	if #Statements == 0 then
		return nil
	end
	
	for _, Statement in pairs(Statements) do
		local Result
		local DateLabel
		if AddSemantic then
			DateLabel = "[[Data di trasmissione::" .. Statement['mainsnak'].datavalue['value'].time .. "|" .. frame:expandTemplate{ title = 'TimeL', args = {Tipo='ITEstesa', Istante=Statement['mainsnak'].datavalue['value'].time} } .. "]]"
		else
			DateLabel = frame:expandTemplate{ title = 'TimeL', args = {Tipo='ITEstesa', Istante=Statement['mainsnak'].datavalue['value'].time} }
		end
		
		Result = '<li>' .. DateLabel .. " su ''" .. Statement['qualifiers']['P4'][1].datavalue['value'] .. "'' (" .. Statement['qualifiers']['P34'][1].datavalue['value'] .. ")</li>"
		
		Results[#Results + 1] = Result
	end
	
	return '<ul>' .. table.concat(Results, string.char(10)) .. '</ul>'
end
function p.ListActors(frame)
	local Actors = p.GetActors(frame, true)
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
		--Link = '[[' .. EpisodeTitle .. '|' .. EpisodeTitle .. ']]'
		Link = LabelOrLink(EpisodeTitle['id'])
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

	Result['SeasonNumber'] = string.format('%u', Item.claims['P18'][1].mainsnak.datavalue.value.amount)
	if Item.claims['P16'] then
		SeriesQ = Item.claims['P16'][1].mainsnak.datavalue.value.id
	else
		SeriesQ = mw.wikibase.getEntity(Item.claims['P14'][1].mainsnak.datavalue.value.id).claims['P16'][1].mainsnak.datavalue.value.id
	end
	
	Result['SeriesName'] = mw.wikibase.getLabel(SeriesQ)
	Result['FileName'] = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1].mainsnak.datavalue.value
	Result['SeriesAbbr'] = mw.wikibase.getEntity(SeriesQ)['claims']['P24'][1].mainsnak.datavalue.value
	
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
	
	--return frame:expandTemplate{ title = 'DataBoxEpisodio' } .. string.char(10) .. "[[" .. mw.title.getCurrentTitle().text .. "]] è un episodio della stagione " .. SeasonData.SeasonNumber .. " di ''[[" .. SeasonData.SeriesName .. "]]''." .. string.char(10)
	return "[[" .. mw.title.getCurrentTitle().text .. "]] è un episodio della stagione " .. SeasonData.SeasonNumber .. " di ''[[" .. SeasonData.SeriesName .. "]]''." .. string.char(10)
end
function p.IncipitTree(frame)
	local SeasonData = p.SeasonInfoRaw()
	mw.smw.set("Serie=" .. SeasonData.SeriesName)
	mw.smw.set("Istanza=Episodio di " .. SeasonData.SeriesAbbr)
	mw.smw.set("Stagione=" .. SeasonData.SeasonNumber)
	
	local SeasonOrdinals =
	{
		 "prima",
		 "seconda",
		 "terza",
		 "quarta",
		 "quinta",
		 "sesta",
		 "settima",
		 "ottava",
		 "nona",
		 "decima"
	}
	
	if not mw.wikibase.getDescription() then
		if not mw.wikibase.getEntity().claims['P20'] then
			return "'''''" .. mw.title.getCurrentTitle().text .. "''''' è un episodio della [[Stagione " .. SeasonData.SeasonNumber .. " di " .. SeasonData.SeriesAbbr .. "|" .. SeasonOrdinals[tonumber(SeasonData.SeasonNumber)] .. " stagione]] di ''[[" .. SeasonData.SeriesName .. "]]''." .. string.char(10)
		else
			return "''''" .. mw.title.getCurrentTitle().text .. "'''' è " .. 	mw.wikibase.getEntity().claims['P20'][1].mainsnak.datavalue['value'] .. string.char(10)
		end
	else
		--return "'''''" .. mw.title.getCurrentTitle().text .. "'''''" .. " è " .. mw.wikibase.getDescription() .. string.char(10)
		return "'''''" .. mw.title.getCurrentTitle().text .. "'''''" .. " è " .. DescrWithTemplate(frame) .. string.char(10)
	end
end
return p