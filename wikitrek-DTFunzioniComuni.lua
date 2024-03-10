-- [P2G] Auto upload by PageToGitHub on 2024-03-10T17:16:58+01:00
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

--------------------------------------------------------------------------------
-- Return a specific Property from Item and/or Instance and/or
-- Instance of Instance.
-- Return the single or multiple values of the Property
--
-- @param Property The property whose values are returned
-- @param Depth How far to go on the tree: 1 - item only,
--                                         2 - item and Instance,
--                                         3 - item, Instance and
--                                             Instance of Instance
-- @param Aggregate Wether to aggregate results or return upon first match
-- @param[opt=false] SkipItem Don't return value for current item,
--                            return Instance and Instance of Instance only
-- @param[opt=false] ForceString Force to return string even in case of Page 
--                               that should return link
-- @return Table with single value or array of values
--------------------------------------------------------------------------------
function p.PropertiesOnTree(Property, Depth, Aggregate, SkipItem, ForceString)
	local CurrentItem = mw.wikibase.getEntity()
	local InstanceItem = nil
	local InstanceInstanceItem = nil
	local ResultsArray = nil
	if not CurrentItem then
		CurrentItem = mw.wikibase.getEntity('Q1')
	end
	
	if Depth == nil or Depth < 1 then
		Depth = 1
	end
	if Depth > 3 then
		Depth = 3
	end
	if SkipItem == nil then
		SkipItem = false
	end
	ForceString = ForceString or false
	
	if Depth > 1 and CurrentItem['claims']['P14'] then
		--Set instance of
		InstanceItem = mw.wikibase.getEntity(CurrentItem['claims']['P14'][1].mainsnak.datavalue.value['id'])
		if Depth > 2 and InstanceItem['claims']['P14'] then
			--Set instance of instance
			InstanceInstanceItem = mw.wikibase.getEntity(InstanceItem['claims']['P14'][1].mainsnak.datavalue.value['id'])
		end
	end
	
	--[=[
	ResultsArray[#ResultsArray + 1] = Property .. " - " .. Depth .. " - " .. tostring(Aggregate)
	ResultsArray[#ResultsArray + 1] = Property .. " - " .. Depth .. " - " .. tostring(InstanceInstanceItem)
	
	if CurrentItem.claims[Property] then
		ResultsArray[#ResultsArray + 1] = LabelOrLink(CurrentItem.claims[Property][1].mainsnak.datavalue.value.id)
		if not Aggregate then
			return resultsArray
		end 
	end]=]
	
	local QList = {}
	if SkipItem then
		QList = {InstanceItem, InstanceInstanceItem}
	else
		QList = {CurrentItem, InstanceItem, InstanceInstanceItem}
	end
	
	for _, Item in pairs(QList) do
		--ResultsArray[#ResultsArray + 1] = "For - " .. Item.id 
		if Item ~= nil and Item.claims[Property] then
			local Values = Item.claims[Property]
			-- Only initialize ResultsArray if the Property exist at least once along the tree
			if ResultsArray == nil then
				ResultsArray = {}
			end
			
			for _, SnakValue in pairs(Values) do
				if SnakValue.mainsnak.datavalue.value.amount ~= nil then
					--ResultsArray[#ResultsArray + 1] = string.format('%u', SnakValue.mainsnak.datavalue.value.amount)
					table.insert(ResultsArray, string.format('%u', SnakValue.mainsnak.datavalue.value.amount))
				elseif SnakValue.mainsnak.datavalue.value.id ~= nil then
					--ResultsArray[#ResultsArray + 1] = LabelOrLink(SnakValue.mainsnak.datavalue.value.id)
					table.insert(ResultsArray, LabelOrLink(SnakValue.mainsnak.datavalue.value.id, nil, nil, nil, ForceString))
				else
					--ResultsArray[#ResultsArray + 1] = SnakValue.mainsnak.datavalue.value
					table.insert(ResultsArray, SnakValue.mainsnak.datavalue.value)
				end
			end
			if not Aggregate then
				return table.concat(ResultsArray)
			end
		end
	end
	
	return ResultsArray
end
function p.SeriesTree(frame)
	--return table.concat(p.PropertiesOnTree("P16", 3, false), "</br>")
	return p.PropertiesOnTree("P16", 3, false)
end
--------------------------------------------------------------------------------
-- Build and return the list of categories for a specific page
--
-- @param {Frame} Info from MW session
-- @return {string} List of properties in Wikitext
--------------------------------------------------------------------------------
function p.CategoryTree(frame)
	local AZInstancesMember = {Q23 = "Personaggi", Q18 = "Specie", Q95 = "Pianeti", Q19 = "Cast", Q52 = "Cast"}
	--local CurrentItem = mw.wikibase.getEntity()
	local CurrentQ
	local UpperCategories
	local AZCategory = ''
	local SpeciesCategory = ''
	
	if mw.wikibase.getEntity() then
		CurrentQ = mw.wikibase.getEntity().claims['P14'][1].mainsnak.datavalue.value.id
	else
		return ""
	end
	
	if AZInstancesMember[CurrentQ] ~= nil then
		local FirstLetter
		if mw.wikibase.getEntity().claims['P8'] ~= nil then
			--Manual criteria has precedence
			FirstLetter = string.upper(string.sub(mw.wikibase.getEntity().claims['P8'][1].mainsnak.datavalue.value, 1, 1))
		else
			local Label = mw.wikibase.getLabel()
			if AZInstancesMember[CurrentQ] == "Personaggi" or AZInstancesMember[CurrentQ] == "Cast" then
				--Person or character: process surname
				local Match = string.match(Label, "[^%s]+$")
				FirstLetter = string.upper(string.sub(Match, 1, 1))
			else
				--No person: take first letter
				FirstLetter = string.upper(string.sub(mw.wikibase.getLabel(), 1, 1))
			end
		end 
		if string.find(FirstLetter, "%d") ~= nil then
			FirstLetter = "0-9"
		end
		
		AZCategory = "[[Category:" .. AZInstancesMember[CurrentQ] .. " - " .. FirstLetter .. "]]"
		
		-- Check if item has Species (P65) property
		if mw.wikibase.getEntity().claims['P65'] ~= nil then
			SpeciesCategory = "[[Category:" .. AZInstancesMember[CurrentQ] .. " - " .. mw.wikibase.getLabelByLang(mw.wikibase.getEntity().claims['P65'][1].mainsnak.datavalue.value.id, "it") .. "]]"
		end
		
		return (p.PropertiesOnTree("P68", 1, false) or "") .. AZCategory .. SpeciesCategory
	else
		UpperCategories = p.PropertiesOnTree("P68", 2, true)
		
		if type(UpperCategories) == "table" then
			return table.concat(UpperCategories)
		else
			return UpperCategories
		end
	end
end
function p.UpperCategoryTree(frame)
	return p.PropertiesOnTree("P69", 1, false)
end
function p.IconTree(frame)
	local ImageName
	
	--return table.concat(p.PropertiesOnTree("P3", 3, false), "</br>")
	--ImageName = p.PropertiesOnTree("P3", 3, false)[1]
	ImageName = p.PropertiesOnTree("P3", 3, false)
	if ImageName == nil or ImageName == '' then
		local CurrentItem
		
		CurrentItem = mw.wikibase.getEntity()
		-- Takes icon from SERIES P16
		if CurrentItem.claims['P16'] ~= nil then
			ImageName = mw.wikibase.getEntity(CurrentItem.claims['P16'][1].mainsnak.datavalue.value.id).claims['P3'][1].mainsnak.datavalue.value
		end
	end
	
	return ImageName
end
function p.SeasonTree(frame)
	--return table.concat(p.PropertiesOnTree("P18", 3, false), "</br>")
	return p.PropertiesOnTree("P18", 3, false)
end
function p.AffiliationTree(frame)
	--return table.concat(p.PropertiesOnTree("P40", 3, false), "</br>")
	return p.PropertiesOnTree("P40", 3, false)
end
function p.OperatorTree(frame)
	--return table.concat(p.PropertiesOnTree("P41", 3, false), "</br>")
	return p.PropertiesOnTree("P41", 3, false)
end
return p