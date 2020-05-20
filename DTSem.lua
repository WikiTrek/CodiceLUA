-- [P2G] Auto upload by PageToGitHub on 2020-05-20T23:25:55+02:00
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
	return "[[Has type::" .. Type .. "|''Date'']]"
end
function p.LabelByLang2(frame)
	local Lang = frame.args['Lingua']
	local Item = frame.args['Item']
	if not Lang then
		Lang = 'it'
	end
	
	if not Item then
		Item = mw.wikibase.getEntityIdForCurrentPage()
	end
	if not Item then
		Item = 'Q1'
	end
	
	return mw.wikibase.getLabelByLang(Item, Lang)
end
function p.FirstSemantic(frame)
	local query = '[[Category:Episodi]] OR [[Category:Film]][[Character::Spock]]|?Actor'
	local result = mw.smw.ask(query)
	--return result
	
	local List = {}
	for _, Row in pairs(result) do
		local Items = {}
		for _, Field in pairs(Row) do
			Items[#Items + 1] = Field
		end
		List[#List + 1] = "*" .. table.concat(Items, ', ')
	end
	
	return table.concat(List, string.char(10))
end

function p.EsempioDataSem(frame)
	local Date = "2019-03-07"
	
	return "[[Prima TV CBS::" .. Date .. "|" .. frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=Date}} .. "]]"
end
return p