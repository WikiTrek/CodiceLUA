-- [P2G] Auto upload by PageToGitHub on 2022-08-21T13:20:29+02:00
-- [P2G] This code from page Modulo:wikitrek-DTSem
-- Keyword: wikitrek
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
--- Function to calculate the number of seasons of a series
-- 
-- @param ShortName The short name of the series as in P24
-- @return Integer Number of seasons
function p.SeasonsQty(ShortName)
	local QueryResult
	local Max
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
	Max = QueryResult[1]["Stagione"]
    if QueryResult == nil or Max < 0 then
        return 0
    else
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
	
	if ShortName == "Serie Classica" or ShortName == "Serie Animata" then
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
    	return p.RecurringList(Pages, Series)    	
	end
	
	--return table.concat(Results, string.char(10))
end
--- Helper to extract recurring characters and list them
-- 
-- @param Pages Array of characters' page name
-- @return String Bullet list of characters and episodes
function p.RecurringList(Pages, Series)
	local Results = {}
	
    if type(Pages) == "table" then
    	for _, Page in ipairs(Pages.results) do
    		local Count
    		local Episodes = {}
        	local List = {}
        	-- Page.fulltext						represents Page name
        	
        	--Count = mw.smw.ask('[[Serie::' .. Series .. ']][[Personaggio::' .. Page.fulltext .. ']]|format=count')
        	Episodes = mw.smw.ask('[[Serie::' .. Series .. ']][[Personaggio::' .. Page.fulltext .. ']]|sort=Numero di produzione|order=asc')
        	
        	if (Episodes ~= nil) and (#Episodes > 0) then
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
        		table.insert(Results, "* '''[[" .. Page.fulltext .. "]]''' (" .. #Episodes .. "): " .. table.concat(List, ", "))
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
	local queryResult = mw.smw.ask("[[Serie::Star Trek: Strange New Worlds]][[Personaggio::T'Pring]]|sort=Numero di produzione|order=asc")
    
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