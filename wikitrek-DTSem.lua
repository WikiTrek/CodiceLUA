-- [P2G] Auto upload by PageToGitHub on 2022-05-12T12:57:35+02:00
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
	
	-- {{#ask: [[Istanza::Episodio di Discovery]]|?Stagione|format=max}}
	QueryResult = mw.smw.ask('[[Istanza::Episodio di ' .. ShortName .. ']]|?Stagione|format=max')
	
    if QueryResult == nil or QueryResult[1] < 0 then
        return 0
    else
    	return QueryResult
    end
end
return p