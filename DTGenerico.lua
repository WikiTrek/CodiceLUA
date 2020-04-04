-- [P2G] Auto upload by PageToGitHub on 2020-04-04T17:01:47+02:00
-- [P2G] This code from page Modulo:DTGenerico
-- Keyword: wikitrek
local TableFromArray = require('Modulo:FunzioniGeneriche').TableFromArray
local LabelOrLink = require('Modulo:DTBase').LabelOrLink
local GenericValue = require('Modulo:DTBase').GenericValue
local p = {}
function p.QFromP(Property)
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	return Item['claims'][Property][1].mainsnak.datavalue['value']['id']
end
function p.Title(frame)
	-- |FileIcona=dsg.png
	local ItemQ
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	--ItemQ = Item['claims']['P14'][1].mainsnak.datavalue['value']['id']
	ItemQ = p.QFromP('P14')
	--SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	--FileName = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	--IconFileName = Item['claims']['P3'][1].mainsnak.datavalue['value']
	--return ItemQ
	--return mw.wikibase.getEntity(ItemQ)['claims']['P3'][1].mainsnak.datavalue['value']
	
	return mw.wikibase.getLabelByLang(ItemQ, 'it')
end
function p.ListAllP(frame)
	local AllP
	local AllRows = {}
	local HTMLTable
	local ExcludeP = {P37 = true, P3 = true, P26 = true}
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	AllP = mw.wikibase.orderProperties(Item:getProperties())
	for _, Property in pairs(AllP) do
		if not ExcludeP[Property] then
			local Header = {Property, mw.wikibase.getLabelByLang(Property, 'it') .. ":"} --'-' .. Property .. ":"}
			--local Value = Item['claims'][Property][1].mainsnak.datavalue['value']
			local Values = Item['claims'][Property]
			local AccValues = {}
			for _, SnakValue in pairs(Values) do
				local Value = SnakValue.mainsnak.datavalue['value']
				if (type(Value) == "table") then
					if Value['entity-type'] == 'item' then
						AccValues[#AccValues + 1] = LabelOrLink(Value['id'])
					elseif SnakValue.mainsnak.datavalue['type'] == 'time' then
						AccValues[#AccValues + 1] = frame:expandTemplate{title = 'TimeL', args = {Tipo='ITEstesa', Istante=Value['time']}}
					else
						AccValues[#AccValues + 1] = 'TABLE'
					end
				else
					AccValues[#AccValues + 1] = Value
				end
			end
			AllRows[#AllRows + 1] = {Header, AccValues}
			--[==[
			if (type(Value) == "table") then
				if Value['entity-type'] == 'item' then
					AllRows[#AllRows + 1] = {Header, LabelOrLink(Value['id'])} 
				else
					AllRows[#AllRows + 1] = {Header, 'TABLE'}
				end
			else
				AllRows[#AllRows + 1] = {Header, Value}
			end
			]==]
		end
	end
	
	HTMLTable = TableFromArray(AllRows)
	HTMLTable
		:addClass('infobox')
	
	-- return table.concat(AllRows, "<br />" .. string.char(10)) .. string.char(10)
	-- return HTMLTable
	return tostring(HTMLTable)
end
function p.Incipit(frame)
	--local SeasonData = p.SeasonInfoRaw()
	
	--return frame:expandTemplate{ title = 'DataBoxEpisodio' } .. string.char(10) .. "[[" .. mw.title.getCurrentTitle().text .. "]] è un episodio della stagione " .. SeasonData.SeasonNumber .. " di ''[[" .. SeasonData.SeriesName .. "]]''." .. string.char(10)
	return "'''" .. mw.title.getCurrentTitle.text .. "''' è un " .. mw.wikibase.getLabelByLang(p.QFromP('P14'), 'it') .. string.char(10)
end
	
--[==[
function p.ExtLinks(frame)
	local AllRows
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local LinksStatements = Item:getAllStatements('P26')
	for _, LinkStatement in pairs(LinksStatements) do
		local LinkURI = LinkStatement.mainsnak.datavalue['value']
		local LinkTitle = LinkStatement['qualifiers']['P20'][1].datavalue['value']
		local LinkID = LinkStatement['qualifiers']['P19'][1].datavalue['value']
		local LinkWiki = "[" .. LinkURI .. " ''" .. mw.text.nowiki(LinkTitle) .. "''], " .. LinkID
		
		if not AllRows then
			AllRows = "* " .. LinkWiki
		else
			AllRows = AllRows .. string.char(10) .. "* " .. LinkWiki
		end
	end
	
	return AllRows .. string.char(10) .. string.char(10) .. "=== Interwiki ===" .. string.char(10) .. "* " .. frame:expandTemplate{title = 'InterlinkMA', args = {Nome=Item:getSitelink("enma")}} .. string.char(10) .. p.SiteLinksInterwiki()
end
function p.Categories(frame)
	local Opening = '[[Categoria:'
	local CategoryP = 'P30'
	
	local InstanceQ
	local SeriesQ
	
	local AllCategories = {}
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local ItemCategories = Item:getAllStatements(CategoryP)
	for _, ItemCategory in pairs(ItemCategories) do
		AllCategories[#AllCategories + 1] = Opening .. ItemCategory.mainsnak.datavalue['value'] .. ']]'
	end
	
	InstanceQ = mw.wikibase.getEntity(Item['claims']['P14'][1].mainsnak.datavalue.value['id'])
	local InstanceCategories = InstanceQ:getAllStatements(CategoryP)
	for _, InstanceCategory in pairs(InstanceCategories) do
		AllCategories[#AllCategories + 1] = Opening .. InstanceCategory.mainsnak.datavalue['value'] .. ']]'
	end
	
	--Non ha senso aggiungere categoria per la serie perchè diventerebbe troppo grande
	--[===[
	SeriesQ = mw.wikibase.getEntity(Item['claims']['P16'][1].mainsnak.datavalue.value['id'])
	local SeriesCategories = SeriesQ:getAllStatements(CategoryP)
	for _, SeriesCategory in pairs(SeriesCategories) do
		AllCategories[#AllCategories + 1] = Opening .. SeriesCategory.mainsnak.datavalue['value'] .. ']]'
	end
	]===]

	return table.concat(AllCategories, string.char(10))
end
function p.SiteLinksInterwiki()
	-- Esempio
	-- [[:memoryalpha:{{{Nome}}}|''{{{Nome}}}'']], Memory Alpha
	local AllLinks = {}
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	local SiteLinks = Item['sitelinks']
	local Titles = {
		wikitrek = 'WikiTrek',
		datatrek = 'DataTrek',
		enma = 'Memory Alpha (inglese)',
		itma = 'Memory Alpha (italiano)',
		enmb = 'Memory Beta (inglese)',
		sto = 'Star Trek Online wiki',
		enwiki = 'Wikipedia (inglese)',
		itwiki = 'Wikipedia (inglese)'
	}
	for _, SiteLink in pairs(SiteLinks) do
		local TitleLabel
		--[===[
		if not Titles[SiteLink['site']] then
			TitleLabel = SiteLink['site']
		else
			TitleLabel = Titles[SiteLink['site']]
		end
		]===]
		TitleLabel = Titles[SiteLink['site']] or SiteLink['site']
		
		if string.find(string.lower(TitleLabel), 'datatrek') then
			-- Un link a DataTrek deve portare alla Entità
			AllLinks[#AllLinks + 1] = "* [[:" .. SiteLink['site'] .. ":Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|''" .. SiteLink['title'] .. "'']], Pagina della entità su " .. TitleLabel
		elseif string.find(string.lower(TitleLabel), 'wikitrek') then
			-- Il link a WikiTrek va ignorato perchè è autoreferenziale
		else
			AllLinks[#AllLinks + 1] = "* [[:" .. SiteLink['site'] .. ":" .. SiteLink['title'] .. "|''" .. SiteLink['title'] .. "'']], " .. TitleLabel
		end
	end
	
	return table.concat(AllLinks, string.char(10))
end
function p.LinkToEntity(frame)
	-- La URI si otterrebbe con
	-- mw.wikibase.getEntityUrl()
	-- ma noi usiamo uno InterWiki link
	local Text
	local p = mw.html.create('p')
	
	if mw.wikibase.getEntity() then
		Text = "Modifica i dati nella pagina [[:datatrek-loc:Item:" .. mw.wikibase.getEntityIdForCurrentPage() .. "|della entità su ''DataTrek'']]"
	else
		Text = "Impossibile trovare l'entità collegata"
	end
	
	p
       :css('line-height', '2')
       :css('alignment', 'right')
       :wikitext(Text)
    return  tostring(p)
end
function p.LabelByLang(frame)
	local Item = mw.wikibase.getEntityIdForCurrentPage()
	local Lang = frame.args['Lingua']
	if not Item then
		Item = 'Q1'
	end
	
	return mw.wikibase.getLabelByLang(Item, Lang)
end
function p.ItemIcon()
	-- |FileIcona=dsg.png
	local IconFileName
	
	local Item = mw.wikibase.getEntity()
	if not Item then
		Item = mw.wikibase.getEntity('Q1')
	end
	
	--SeriesQ = Item['claims']['P16'][1]['mainsnak'].datavalue['value']['id']
	--FileName = mw.wikibase.getEntity(SeriesQ)['claims']['P3'][1]['mainsnak'].datavalue['value']
	IconFileName = Item['claims']['P3'][1].mainsnak.datavalue['value']
	
	return FileName
end ]==]
return p