-- [P2G] Auto upload by PageToGitHub on 2020-05-20T23:27:23+02:00
-- [P2G] This code from page Modulo:DTSem
-- Keyword: wikitrek
local p = {}
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
	
	Type = Item['claims']['P49'][1].mainsnak.datavalue.value
	return "[[Has type::" .. Type .. "|''" .. Type .. "'']]"
end
return p