-- [P2G] Auto upload by PageToGitHub on 2022-06-06T15:50:43+02:00
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
	QueryResult = mw.smw.ask(PrefixText .. ShortName .. ']]|?Stagione|format=max')
	
	-- See https://github.com/SemanticMediaWiki/SemanticScribunto/blob/master/docs/mw.smw.ask.md#result
	-- for return value example
	Max = QueryResult[1]["Stagione"]
    if QueryResult == nil or Max < 0 then
        return 0
    else
    	return Max
    end
end
return p