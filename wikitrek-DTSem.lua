-- [P2G] Auto upload by PageToGitHub on 2024-06-18T10:59:00+02:00
-- [P2G] This code from page Modulo:wikitrek-DTSem
-- <nowiki>
--------------------------------------------------------------------------------
-- This module handles generic semantic functions to support modules
-- Comments are compatible with LDoc https://github.com/lunarmodules/ldoc
--
-- @module p
-- @author Luca Mauri [[Utente:Lucamauri]]
-- @keyword: wikitrek
-- Keyword: wikitrek
--------------------------------------------------------------------------------
local p = {}

local QFromP = require('Modulo:DTGenerico').QFromP

function p.TypeFromDT(frame)
	local Item
	local Type
	
	Item = mw.wikibase.getEntity()
	
	if not Item then
		Item = mw.wikibase.getEntity(frame.args['Item'])
	end
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if (not Item['claims']) or (not Item['claims']['P49']) then
		return "ERROR"
	else
		Type = Item['claims']['P49'][1].mainsnak.datavalue.value
		return "[[Has type::" .. Type .. "|''" .. Type .. "'']]"
	end
end
function p.DescrFromDT(frame)
	-- ** [[Has property description::DataTrek ID@en]]
	-- ** [[Has property description::Identificativo DataTrek@it]]
	local Item
	local Value
	local AllLabels
	
	Item = mw.wikibase.getEntity()
	
	if not Item then
		Item = mw.wikibase.getEntity(frame.args['Item'])
	end
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local Labels = Item.labels
	for _, Label in pairs(Labels) do
		Value = "** " .. "[[Has property description::" .. Label.value .. "@" .. Label.language .. "]]"
		if not AllLabels then
			AllLabels = Value
		else
			AllLabels = AllLabels .. string.char(10) .. Value
		end
	end
	
	return string.char(10) .. AllLabels
end
--------------------------------------------------------------------------------
-- Take parameters out of the frame and pass them to p._buildUniversalIncipit().
-- Return the result.
--
-- @param {Frame} Info from MW session
-- @return {string} The full incipit wikitext
--------------------------------------------------------------------------------
function p.URIFromatterFromDT(frame)
	local Item
	local Type
	
	Item = mw.wikibase.getEntity()
	
	if not Item then
		Item = mw.wikibase.getEntity(frame.args['Item'])
	end
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	if (not Item['claims']) or (not Item['claims']['P5']) then
		return "ERROR"
	else
		Type = Item['claims']['P5'][1].mainsnak.datavalue.value
		return "[[External formatter uri::" .. Type .. "|''" .. Type .. "'']]"
	end
end

--------------------------------------------------------------------------------
-- Generic value parser from arbitrary Item and Property
-- Return the result.
--
-- @param {Item} The Entity
-- @param {Property} String containing the property identifier and number
-- @return {string} Value of the mainsnak
--------------------------------------------------------------------------------
function p.GenericFromDT(Item, Property)
	if (not Item['claims']) or (not Item['claims'][Property]) then
		return "ERROR"
	else
		return Item['claims'][Property][1].mainsnak.datavalue.value
	end
end

--- Function to calculate the number of seasons of a series
-- 
-- @param ShortName The short name of the series as in P24
-- @return Integer Number of seasons
function p.SeasonsQty(ShortName)
	local QueryResult
	local Max = 0
	local PrefixText
	
	if ShortName == "Serie Classica" or ShortName == "Serie Animata" then
		PrefixText = '[[Istanza::Episodio della '
	else
		PrefixText = '[[Istanza::Episodio di '
	end
	
	-- {{#ask: [[Istanza::Episodio di Discovery]]|?Stagione|format=max}}
	--QueryResult = mw.smw.ask('[[Istanza::Episodio di ' .. ShortName .. ']]|?Stagione|format=max')
	QueryResult = mw.smw.ask(PrefixText .. ShortName .. ']]|?Stagione|sort=Stagione|order=desc|format=max')
	-- See https://github.com/SemanticMediaWiki/SemanticScribunto/blob/master/docs/mw.smw.ask.md#result
	-- for return value example
    if QueryResult == nil or Max < 0 then
        return 0
    else
    	Max = QueryResult[1]["Stagione"]
    	return Max
    end
end
--- Function to extract recurring characters and list them
-- 
-- @param frame Context from MediaWiki
-- @return String Bullet list of characters and episodes
function p.RecurringListFromCategory(frame)
	local Results = {}
	local Item
	local CategoryText
	local Pages
	local PagesList = {}
	local Series
	local SeriesShort
	
	if not Item then
		Item = mw.wikibase.getEntity(frame.args['Item'])
	end
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	SeriesShort = mw.wikibase.getEntity(Item.claims['P16'][1].mainsnak.datavalue.value.id).claims['P24'][1].mainsnak.datavalue.value
	Series = mw.wikibase.getLabel(Item.claims['P16'][1].mainsnak.datavalue.value.id)
	
	if SeriesShort == "Serie Classica" or SeriesShort == "Serie Animata" then
		CategoryText = '[[Category:Personaggi della ' .. SeriesShort .. "]]"
	else
		CategoryText = '[[Category:Personaggi di ' .. SeriesShort .. "]]"
	end
	
	Pages = mw.smw.getQueryResult(CategoryText) --PrefixText .. ShortName .. ']]|?Stagione|sort=Stagione|order=desc|format=max')
	-- See https://github.com/SemanticMediaWiki/SemanticScribunto/blob/master/docs/mw.smw.ask.md#result
	-- for return value example
	
	if Pages == nil then
        return "''Nessun risultato''"
    else
    	for _, Page in ipairs(Pages.results) do
    		table.insert(PagesList, Page.fulltext)
    	end
		
    	return p.RecurringList(PagesList, Series)    	
	end
	
	--return table.concat(Results, string.char(10))
end
--- Function to extract recurring characters from all pages and list them
-- 
-- @param frame Context from MediaWiki
-- @return String Bullet list of characters and episodes
function p.RecurringListFull(frame)
	local Results = {}
	local Item
	local InstanceText
	local Pages
	local Series
	local SeriesShort
	local Characters = {}
	local PagesList = {}
	
	if not Item then
		Item = mw.wikibase.getEntity(frame.args['Item'])
	end
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	SeriesShort = mw.wikibase.getEntity(Item.claims['P16'][1].mainsnak.datavalue.value.id).claims['P24'][1].mainsnak.datavalue.value
	Series = mw.wikibase.getLabel(Item.claims['P16'][1].mainsnak.datavalue.value.id)
	
	if SeriesShort == "Serie Classica" or SeriesShort == "Serie Originale" or SeriesShort == "Serie Animata" then
		InstanceText = '[[Istanza::Episodio della ' .. SeriesShort .. "]]"
	else
		InstanceText = '[[Istanza::Episodio di ' .. SeriesShort .. "]]"
	end
	--[==[
	Pages = mw.smw.ask(InstanceText .. "|?Personaggio|order=asc|sort=Numero di produzione")
	
	if Pages == nil then
        return "''Nessun risultato'' (<code>" .. mw.text.nowiki(InstanceText) .. "</code>, )" 
    else
    	--local myResult = ""
        for num, row in pairs(Pages) do
            --myResult = myResult .. '* This is result #' .. num .. '\n'
            mw.smw.set("Test=" .. num)
            for property, data in pairs( row ) do
            	if property == "Personaggio"  then
            		if type(data) == 'table' then
            			for _, Character in pairs(data) do
            				if Characters[Character] == nil then
            					--table.insert(Characters, Character)
            				end
            			end
            		else
            			-- This should never happens
            			table.insert(Characters, "NEXT ONE ->")
            			if Characters[data] == nil then
            				table.insert(Characters, data)
            			end
            		end
            	end
            end
        end
	end
	]==]
	NewPages = mw.smw.getQueryResult(InstanceText .. "|?Personaggio|limit=500|order=asc|sort=Numero di produzione")
	
	for _, Episode in ipairs(NewPages.results) do
		for _, Character in ipairs(Episode.printouts.Personaggio) do
			local CharText = Character.fulltext
			if not Characters[CharText] then
				table.insert(Characters, CharText)
				Characters[CharText] = true
			end
		end
	end

	table.sort(Characters)
	
	if type(Characters) == 'table' and Characters ~= nil then
		for _, Page in ipairs(Characters) do
    		table.insert(PagesList, Page)
    	end
		
		
		return p.RecurringList(PagesList, Series, 3)
		--return #Characters .. " - " .. #Characters .. " - " .. table.concat(PagesList, ", ")
	else
		return "No table"
	end
		
	--return table.concat(Results, string.char(10))
end
--- Helper to extract recurring characters and list them
-- 
-- @param Pages Table containing characters' pages names
-- @param Series String with name of the Series
-- @param[opt=1] MinOccurr Integer with minimum value of occurencies
-- @return String Bullet list of characters and episodes
function p.RecurringList(Pages, Series, MinOccurr)
	local Results = {}
	if not MinOccurr or MinOccurr < 1 then
		MinOccurr = 1
	end
	
    if type(Pages) == "table" then
    	--for _, Page in ipairs(Pages.results) do
    	for _, Page in ipairs(Pages) do	
    		local Count
    		local Episodes = {}
        	local List = {}
        	-- Page.fulltext						represents Page name
        	
        	--Count = mw.smw.ask('[[Serie::' .. Series .. ']][[Personaggio::' .. Page.fulltext .. ']]|format=count')
        	--Episodes = mw.smw.ask('[[Serie::' .. Series .. ']][[Personaggio::' .. Page.fulltext .. ']]|sort=Numero di produzione|order=asc')
        	Episodes = mw.smw.ask('[[Serie::' .. Series .. ']][[Personaggio::' .. Page .. ']]|limit=100|sort=Numero di produzione|order=asc')
        	
        	if (Episodes ~= nil) and (#Episodes > MinOccurr - 1) then
        		--[=[
        		Episodes = mw.smw.getQueryResult('[[Serie::' .. Series .. ']][[Personaggio::' .. Page.fulltext .. ']]|sort=Numero di produzione|order=asc')
        		
        		for _, Episode in ipairs(Episodes.results) do
        			table.insert(List, "[[" .. Episode.fulltext .. "]]")
        		end
        		]=]
        		
        		for num, Episode in pairs(Episodes) do
        			--myResult = myResult .. '* This is result #' .. num .. '\n'
            		for _, Data in pairs(Episode) do
            			if type(Data) == 'table' then
            				table.insert(List, table.concat(Data))
            			else
            				table.insert(List, Data)
            			end
        					
            		end
        		end
        		table.insert(Results, "* '''[[" .. Page .. "]]''' (" .. #Episodes .. "): " .. table.concat(List, ", "))
        	else
        		-- Episode is NULL or number of episodes is LESS the set value
        		--table.insert(Results, "* NULL or ZERO Episodes - " .. mw.text.nowiki('[[Serie::' .. Series .. ']][[Personaggio::' .. Page .. ']]|sort=Numero di produzione|order=asc'))
        	end
    	end
    else
    	return "''Il risultato non è una TABLE''"
    end
	
	return table.concat(Results, string.char(10))
end

-- Return results
function p.Ask(frame)

    if not mw.smw then
        return "mw.smw module not found"
    end
	
    --if frame.args[1] == nil then
    --    return "no parameter found"
    --end
	
	--local queryResult = mw.smw.ask( frame.args )
	--local queryResult = mw.smw.ask("[[Serie::Star Trek: Strange New Worlds]][[Personaggio::T'Pring]]|sort=Numero di produzione|order=asc")
	local queryResult = mw.smw.ask("[[Istanza::Episodio di Picard]]|?Personaggio|order=asc|sort=Numero di produzione")
    
    if queryResult == nil then
        return "(no values)"
    end

    if type( queryResult ) == "table" then
        local myResult = ""
        for num, row in pairs( queryResult ) do
            myResult = myResult .. '* This is result #' .. num .. '\n'
            for property, data in pairs( row ) do
                local dataOutput = data
                if type( data ) == 'table' then
                    dataOutput = mw.text.listToText( data, ', ', ' and ')
                end
                myResult = myResult .. '** ' .. property .. ': ' .. dataOutput .. '\n'
            end
        end
        return myResult
    end

    return queryResult
end
return p