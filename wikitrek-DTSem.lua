-- [P2G] Auto upload by PageToGitHub on 2022-08-20T12:55:26+02:00
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
-- @param ShortName The short name of the series as in P24
-- @return Integer Number of seasons
function p.RecurringListFromCategory(frame)
	local Results = {}
	local Item
	local CategoryText
	local Pages
	
	if not Item then
		Item = mw.wikibase.getEntity(frame.args['Item'])
	end
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	CategoryText = mw.wikibase.getEntity(Item.claims['P16'][1].mainsnak.datavalue.value.id).claims['P24'][1].mainsnak.datavalue.value
	
	if ShortName == "Serie Classica" or ShortName == "Serie Animata" then
		CategoryText = '[[Category:Personaggi della ' .. CategoryText .. "]]"
	else
		CategoryText = '[[Category:Personaggi di ' .. CategoryText .. "]]"
	end
	
	Pages = mw.smw.getQueryResult(CategoryText) --PrefixText .. ShortName .. ']]|?Stagione|sort=Stagione|order=desc|format=max')
	-- See https://github.com/SemanticMediaWiki/SemanticScribunto/blob/master/docs/mw.smw.ask.md#result
	-- for return value example
	
	if Pages == nil then
        return "''Nessun risultato''"
    end

    if type(Pages) == "table" then
    	for _, Page in ipairs(Pages.results) do
        	-- Page.fulltext						represents Page name
        	
        	table.insert(Results, "* " .. Page.fulltext)
    	end
    else
    	return "''Il risultato non è una TABLE''"
    end
	
	--return mw.text.nowiki(CategoryText) .. #Pages
	return table.concat(Results, string.char(10))
end
return p