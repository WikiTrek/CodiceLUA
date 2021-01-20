-- [P2G] Auto upload by PageToGitHub on 2021-01-21T00:35:38+01:00
-- [P2G] This code from page Modulo:wikitrek-DTFunzioniComuni
-- Keyword: wikitrek

local LabelOrLink = require('Modulo:DTBase').LabelOrLink

local p = {}
function p.ImmagineDaFile(Frame)
    local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then return '' end
	
	local results = {}
	local statements = mw.wikibase.getBestStatements(item, 'P3')
	for _, statement in pairs(statements) do
		if statement.mainsnak.snaktype == 'value' then
			local Immagine = statement.mainsnak.datavalue.value
			
			if Immagine then
				results[#results + 1] = '[[File:' .. Immagine .. '|' .. Frame.args.OpzioniImmagine .. ']]'
			else
				results[#results + 1] = 'VUOTO'
			end
		else
			results[#results + 1] = 'ERRORE'
		end
	end
	return table.concat(results, ', ')
end
function p.Date(frame)
	local entity = mw.wikibase.getEntity()
	-- local snak = entity['claims']['P2'][1]

    -- return entity['claims']['P2'][1].value
    return entity.claims['P2'].value
end
function p.Network(frame)
	local entity = mw.wikibase.getEntity()
	local snak = entity['claims']['P2'][1]['qualifiers']['P4'][1]

    return mw.wikibase.renderSnak( snak )
end
function p.URL(frame)
    return mw.wikibase.getEntityUrl()
end
function p.List(frame)
	local entity = mw.wikibase.getEntity()
	local snak = entity['claims']['P2']
	local result = ''
	for index, value in next, snak do
		result = result .. mw.wikibase.renderSnak(value)
	end
end
function p.LinkFromPage(frame)
	local item = mw.wikibase.getEntityIdForCurrentPage()
	if not item then return '' end
	local results = {}
	local statements = mw.wikibase.getBestStatements(item, 'P7')
	for _, statement in pairs(statements) do
		if statement.mainsnak.snaktype == 'value' then
			local value = statement.mainsnak.datavalue.value
			local sitelink = value
			local label = null
			if sitelink then
				if label then
					results[#results + 1] = '[[' .. sitelink .. '|' .. label .. ']]'
				else
					results[#results + 1] = '[[' .. sitelink .. ']]'
				end
			elseif label then
				results[#results + 1] = label
			end
		end
	end
	return table.concat(results, ', ')
end
--- Three dashes indicate the beginning of a function or field documented
-- using the LDoc format
-- @param Property The property whose values are returned
-- @param Depth How far to go on the tree: 1 - item only, 2 - item and Instance, 3 - item, Instance and Instance of Instance
-- @param Aggregate Wether to aggregate results or return the first found
-- @return Table withs strings or wikilinks
function p.PropertiesOnTree(Property, Depth, Aggregate)
	local CurrentItem = mw.wikibase.getEntity()
	local InstanceItem = nil
	local InstanceInstanceItem = nil
	local ResultsArray = {}
	--local ItemQ = mw.wikibase.getEntityIdForCurrentPage()
	if not CurrentItem then
		CurrentItem = mw.wikibase.getEntity('Q1')
	end
	
	if Depth == nil or Depth < 1 then
		Depth = 1
	end
	if Depth > 3 then
		Depth = 3
	end
	
	if Depth > 1 and CurrentItem['claims']['P14'] then
		--Set instance of
		InstanceItem = mw.wikibase.getEntity(CurrentItem['claims']['P14'][1].mainsnak.datavalue.value['id'])
		if Depth > 2 and InstanceItem['claims']['P14'] then
			--Set instance of instance
			InstanceInstanceItem = mw.wikibase.getEntity(InstanceItem['claims']['P14'][1].mainsnak.datavalue.value['id'])
		end
	end
	
	--return Property .. " - " .. Depth .. " - " .. Aggregate
	
	--[=[if CurrentItem.claims[Property] then
		ResultsArray[#ResultsArray + 1] = LabelOrLink(CurrentItem.claims[Property][1].mainsnak.datavalue.value.id)
		if not Aggregate then
			return resultsArray
		end 
	end]=]
	
	for _, Item in pairs({CurrentItem, InstanceItem, InstanceInstanceItem}) do
		ResultsArray[#ResultsArray + 1] = "For - " .. Item.id 
		if Item ~= nil and Item.claims[Property] then
			ResultsArray[#ResultsArray + 1] = Item.id .. " - " .. Property
			--ResultsArray[#ResultsArray + 1] = LabelOrLink(Item.claims[Property][1].mainsnak.datavalue.value.id)
			if not Aggregate then
				return ResultsArray
			end
		end
	end
	
	return ResultsArray
end
function p.TestTree(frame)
	return table.concat(p.PropertiesOnTree("P16", 2, true), "</br>")
end
return p