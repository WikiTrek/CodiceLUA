-- [P2G] Auto upload by PageToGitHub on 2021-06-02T17:51:57+02:00
-- [P2G] This code from page Modulo:wikitrek-DTSem
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
		Value = "** " .. Label.value .. "@" .. Label.language
		if not AllLabels then
			AllLabels = Value
		else
			AllLabels = AllLabels .. string.char(10) .. Value
		end
	end
	
	return string.char(10) .. AllLabels
end
return p