-- [P2G] Auto upload by PageToGitHub on 2020-05-19T22:46:18+02:00
-- [P2G] This code from page Modulo:SemBase
-- Keyword: wikitrek
local p = {}
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